import AppKit
import ApplicationServices
import Carbon

/// Only authoritative AX text can start analysis without a separate confirmation.
enum SelectionTextOrigin {
    case accessibility, scopedAccessibility, clipboard
    var requiresConfirmation: Bool { self != .accessibility }
    /// Route automatic analysis. Unverified PDF and clipboard previews never enter it.
    func analyzeAutomaticallyIfAllowed(requested: Bool, analyze: () -> Void) {
        if requested && self == .accessibility { analyze() }
    }
}

/// Bind a command to a live process. This identity does not identify a browser tab.
struct SelectionCommandIdentity: Equatable {
    let pid: pid_t
    let launchDate: Date?
    func matches(pid: pid_t?, launchDate: Date?) -> Bool {
        self.pid == pid && self.launchDate == launchDate
    }
}

/// Compare an optional captured window without searching other windows.
struct SelectionWindowIdentity<Window: Equatable> {
    let captured: Window?
    func matches(current: Window?) -> Bool { captured == nil || captured == current }
}

/// Keep a fixed AX window reference across the selection and copy workers.
/// The reference is immutable; public AX requests can run on either worker.
final class CapturedSelectionWindow: @unchecked Sendable {
    private struct Window: Equatable {
        let element: AXUIElement
        static func == (lhs: Window, rhs: Window) -> Bool { CFEqual(lhs.element, rhs.element) }
    }
    private static let worker = DispatchQueue(label: "com.selectenglish.window-validation")
    private let pid: pid_t
    private let identity: SelectionWindowIdentity<Window>
    private init(pid: pid_t, window: AXUIElement) {
        self.pid = pid
        identity = SelectionWindowIdentity(captured: Window(element: window))
    }
    private static func focusedWindow(pid: pid_t) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.08)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXUIElement.self)
    }
    static func capture(pid: pid_t) -> CapturedSelectionWindow? {
        guard let window = focusedWindow(pid: pid) else { return nil }
        return CapturedSelectionWindow(pid: pid, window: window)
    }
    /// Validate AX window identity on the serial worker, never on the main actor.
    func isCurrentAsync(permit: SelectionCapturePermit) async -> Bool {
        guard permit.isValid else { return false }
        return await withCheckedContinuation { continuation in
            Self.worker.async {
                guard permit.isValid else { continuation.resume(returning: false); return }
                let current = self.isCurrentOnWorker
                continuation.resume(returning: permit.isValid && current)
            }
        }
    }
    /// Call only on an AX worker. This operation can wait for the existing AX timeout.
    var isCurrentOnWorker: Bool {
        identity.matches(current: Self.focusedWindow(pid: pid).map { Window(element: $0) })
    }
}

/// Register one system hotkey without observing ordinary keyboard events.
final class SelectionHotKey {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var action: (() -> Void)?
    private static let signature: OSType = 0x53454C54
    private(set) var status = "快捷键尚未注册"

    /// Call once on the main thread; Carbon delivers this command on the app event loop.
    func start(action: @escaping () -> Void) {
        self.action = action
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                MemoryLayout<EventHotKeyID>.size, nil, &id) == noErr,
                id.signature == SelectionHotKey.signature, id.id == 1 else { return OSStatus(eventNotHandledErr) }
            Unmanaged<SelectionHotKey>.fromOpaque(context).takeUnretainedValue().action?()
            return noErr
        }, 1, &type, context, &handler)
        guard installed == noErr else { status = "快捷键注册失败（\(installed)），请使用菜单翻译选区。"; return }
        let result = RegisterEventHotKey(UInt32(kVK_ANSI_T), UInt32(controlKey | optionKey | cmdKey),
            EventHotKeyID(signature: Self.signature, id: 1), GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &hotKey)
        status = result == noErr ? "翻译选区快捷键：⌃⌥⌘T（已注册）" : "⌃⌥⌘T 注册失败或被占用（\(result)），请使用菜单。"
    }
    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}
