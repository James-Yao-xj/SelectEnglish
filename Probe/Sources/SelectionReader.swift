import AppKit
import ApplicationServices

/// Return selection text and diagnostic metadata without changing application focus.
enum SelectionReader {
    struct Result {
        let role: String
        let text: String
        let message: String
    }

    /// Read only the given process. Reject a terminated or reused process ID.
    static func read(pid: pid_t, launchDate: Date?) -> Result {
        func failure(_ message: String, role: String = "未知") -> Result {
            Result(role: role, text: "", message: message)
        }
        guard let app = NSRunningApplication(processIdentifier: pid), !app.isTerminated,
              app.launchDate == launchDate else { return failure("触发时的目标应用已退出或进程已改变。") }
        guard AXIsProcessTrusted() else { return failure("当前进程未获得辅助功能授权；请授权后重试。") }
        let element = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(element, 1)
        var focused: CFTypeRef?
        let focusError = AXUIElementCopyAttributeValue(element, kAXFocusedUIElementAttribute as CFString, &focused)
        guard focusError == .success else { return failure("无法获取焦点元素：\(describe(focusError))。") }
        guard let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else {
            return failure("焦点属性返回空值或非元素数据。")
        }
        // The type ID check above makes this CF conversion valid.
        let focusedElement = unsafeBitCast(focused, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(focusedElement, 1)
        var roleValue: CFTypeRef?
        let roleError = AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute as CFString, &roleValue)
        let role = roleError == .success ? (roleValue as? String ?? "非文字角色值") : describe(roleError)
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, &value)
        guard !app.isTerminated else { return failure("目标应用在读取期间退出。", role: role) }
        guard error == .success else { return failure("读取 AXSelectedText：\(describe(error))。", role: role) }
        guard let text = value as? String else { return failure("AXSelectedText 返回空值或非文本数据。", role: role) }
        guard !text.isEmpty else { return failure("AXSelectedText 为空；当前焦点元素没有选中文字。", role: role) }
        return Result(role: role, text: text, message: "已读取 \(text.count) 个字符，请核对是否为完整选区。")
    }

    private static func describe(_ error: AXError) -> String {
        let label: String
        switch error {
        case .success: label = "成功"
        case .apiDisabled: label = "辅助功能 API 未启用"
        case .attributeUnsupported: label = "目标元素不支持此属性"
        case .noValue: label = "此属性没有值（可能无选区）"
        case .cannotComplete: label = "目标应用未能完成请求"
        case .invalidUIElement: label = "焦点元素已失效"
        case .illegalArgument: label = "请求参数无效"
        case .notImplemented: label = "目标应用未实现此功能"
        case .failure: label = "辅助功能请求失败"
        default: label = "其他辅助功能错误"
        }
        return "\(label)（AX \(error.rawValue)）"
    }
}
