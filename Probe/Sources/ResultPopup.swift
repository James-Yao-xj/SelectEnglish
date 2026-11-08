import AppKit

/// Draw a cached paper tile so popup redraws do not regenerate grain or fibers.
private final class KraftPaperView: NSView {
    static let ink = NSColor(srgbRed: 0.23, green: 0.16, blue: 0.10, alpha: 1)
    static let secondaryInk = NSColor(srgbRed: 0.39, green: 0.29, blue: 0.19, alpha: 1)

    private static let tile: NSImage = {
        let size = NSSize(width: 256, height: 256)
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 256,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSColor(srgbRed: 0.87, green: 0.77, blue: 0.61, alpha: 1).setFill()
        NSRect(origin: .zero, size: size).fill()

        // Stable texture prevents the paper from changing when content updates.
        var seed: UInt64 = 0x4B52414654
        func random() -> CGFloat {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat(seed >> 40) / CGFloat(1 << 24)
        }
        for _ in 0..<4200 {
            let shade: CGFloat = random() < 0.55 ? 0 : 1
            NSColor(calibratedWhite: shade, alpha: 0.025 + random() * 0.035).setFill()
            NSRect(x: random() * 256, y: random() * 256,
                   width: 0.6 + random() * 0.8, height: 0.5 + random() * 0.7).fill()
        }
        for _ in 0..<210 {
            let origin = NSPoint(x: random() * 256, y: random() * 256)
            NSColor(calibratedWhite: random() < 0.5 ? 0.15 : 1, alpha: 0.07).setStroke()
            let fiber = NSBezierPath()
            fiber.lineWidth = 0.3
            fiber.move(to: origin)
            fiber.curve(to: NSPoint(x: origin.x + 3 + random() * 9, y: origin.y + random() * 2 - 1),
                controlPoint1: NSPoint(x: origin.x + 2, y: origin.y + 0.6),
                controlPoint2: NSPoint(x: origin.x + 4, y: origin.y - 0.6))
            fiber.stroke()
        }
        let image = NSImage(size: size)
        image.addRepresentation(bitmap)
        return image
    }()

    override func draw(_ dirtyRect: NSRect) {
        NSColor(patternImage: Self.tile).setFill()
        bounds.fill()
        Self.secondaryInk.withAlphaComponent(0.18).setStroke()
        let rim = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 9.5, yRadius: 9.5)
        rim.lineWidth = 1
        rim.stroke()
    }
}

/// A borderless panel that does not activate the app when it appears.
private final class LookupPanel: NSPanel {
    var onEscape: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { onEscape?() }
}

/// Present a dictionary-style result near the pointer without moving focus from the source app.
final class ResultPopup: NSObject {
    let sourceView = NSTextView()
    let resultView = NSTextView()
    let stateLabel = NSTextField(wrappingLabelWithString: "选中英文后，用力点按触控板即可翻译。")
    let sourceLabel = NSTextField(labelWithString: "SelectEnglish")
    var onDismiss: (() -> Void)?
    var onRetry: (() -> Void)?
    var onFavorite: (() -> Void)?
    var onSettings: (() -> Void)?
    var onCancel: (() -> Void)?
    private let panel = LookupPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 250),
                                    styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    private let resultScroll = NSScrollView()
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var dismissalState = PopupDismissalState()
    var hasPendingCapture: Bool { dismissalState.hasPendingCapture }
    /// Retain the actual trigger position so network updates do not recenter the popup.
    private var anchor = CGPoint.zero

    override init() {
        super.init()
        panel.title = "SelectEnglish · 翻译"
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
        panel.onEscape = { [weak self] in self?.dismiss() }
        panel.appearance = NSAppearance(named: .aqua)
        let material = KraftPaperView()
        material.wantsLayer = true
        material.layer?.cornerRadius = 10
        material.layer?.masksToBounds = true
        panel.contentView = material
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        material.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: material.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: material.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: material.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: material.bottomAnchor, constant: -14)
        ])
        let header = NSStackView()
        header.spacing = 8
        sourceLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        sourceLabel.textColor = KraftPaperView.secondaryInk
        sourceLabel.lineBreakMode = .byTruncatingTail
        sourceLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        header.addArrangedSubview(sourceLabel)
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        header.addArrangedSubview(spacer)
        header.addArrangedSubview(icon("gearshape", label: "AI 设置", action: #selector(settings)))
        header.addArrangedSubview(icon("xmark", label: "关闭翻译", action: #selector(close)))
        stack.addArrangedSubview(header)
        let sourceScroll = textScroll(sourceView)
        sourceView.font = .systemFont(ofSize: 13)
        sourceView.textColor = KraftPaperView.secondaryInk
        sourceScroll.heightAnchor.constraint(equalToConstant: 48).isActive = true
        stack.addArrangedSubview(sourceScroll)
        stateLabel.font = .systemFont(ofSize: 12)
        stateLabel.textColor = KraftPaperView.secondaryInk
        stateLabel.maximumNumberOfLines = 3
        stack.addArrangedSubview(stateLabel)
        configure(resultView, in: resultScroll)
        resultView.font = .systemFont(ofSize: 14)
        resultScroll.setContentHuggingPriority(.defaultLow, for: .vertical)
        resultScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
        stack.addArrangedSubview(resultScroll)
        let footer = NSStackView()
        footer.spacing = 12
        footer.addArrangedSubview(action("重试", selector: #selector(retry)))
        footer.addArrangedSubview(action("收藏", selector: #selector(favorite)))
        footer.addArrangedSubview(action("取消", selector: #selector(cancel)))
        let footerSpace = NSView()
        footerSpace.setContentHuggingPriority(.defaultLow, for: .horizontal)
        footer.addArrangedSubview(footerSpace)
        stack.addArrangedSubview(footer)
        for child in stack.arrangedSubviews { child.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown {
                if self.panel.isVisible && event.keyCode == 53 { self.dismiss(); return nil }
            } else { self.handleMouseDown(event) }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleMouseDown(event)
        }

    }

    func beginCapture(generation: Int, startedAt: TimeInterval) {
        dismissalState.beginCapture(generation: generation, startedAt: startedAt)
    }

    func completeCapture(generation: Int) -> Bool {
        dismissalState.completeCapture(generation: generation)
    }

    func invalidateCapture() { dismissalState.invalidateCapture() }

    /// Both event monitors use the same decision, including when AX is pending but hidden.
    private func handleMouseDown(_ event: NSEvent) {
        if dismissalState.shouldDismissMouseDown(timestamp: event.timestamp, popupVisible: panel.isVisible,
            pointInsidePopup: panel.frame.contains(PopupMouseEvent.screenPoint(for: event))) { dismiss() }
    }

    private func configure(_ view: NSTextView, in scroll: NSScrollView) {
        view.frame = NSRect(x: 0, y: 0, width: 388, height: 50)
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
        view.textColor = KraftPaperView.ink
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = false
        view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = true
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.documentView = view
    }

    private func textScroll(_ view: NSTextView) -> NSScrollView {
        let scroll = NSScrollView()
        configure(view, in: scroll)
        return scroll
    }

    private func icon(_ name: String, label: String, action: Selector) -> NSButton {
        let button = NSButton(image: NSImage(systemSymbolName: name, accessibilityDescription: label)!, target: self, action: action)
        button.isBordered = false
        button.contentTintColor = KraftPaperView.secondaryInk
        button.controlSize = .small
        button.toolTip = label
        button.setAccessibilityLabel(label)
        return button
    }

    private func action(_ title: String, selector: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: selector)
        button.bezelStyle = .inline
        button.controlSize = .small
        button.font = .systemFont(ofSize: 12)
        button.attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 12), .foregroundColor: KraftPaperView.secondaryInk
        ])
        return button
    }

    /// Make only this nonactivating panel key so Escape works; do not activate the app.
    func show(at point: CGPoint) {
        anchor = point
        refresh()
        panel.makeKeyAndOrderFront(nil)
    }

    /// Resize around the same trigger anchor, within the current monitor's visible area.
    func refresh() {
        let width: CGFloat = 388
        let attributes: [NSAttributedString.Key: Any] = [.font: resultView.font ?? NSFont.systemFont(ofSize: 14)]
        let content = resultView.attributedString().length > 0 ? resultView.attributedString() : NSAttributedString(string: "", attributes: attributes)
        let contentHeight = content.boundingRect(with: NSSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading]).height
        let statusHeight = (stateLabel.stringValue as NSString).boundingRect(with: NSSize(width: width, height: 100), options: [.usesLineFragmentOrigin], attributes: [.font: NSFont.systemFont(ofSize: 12)]).height
        let height = 154 + min(310, max(24, contentHeight + 8)) + min(48, max(16, statusHeight))
        panel.setFrame(PopupGeometry.frame(anchor: anchor, visibleFrames: NSScreen.screens.map(\.visibleFrame), contentHeight: height, screenFrames: NSScreen.screens.map(\.frame)), display: true)
    }

    /// Use readable section headings in a single scrollable dictionary-style result.
    func display(_ analysis: Analysis) {
        let body = NSMutableAttributedString()
        func append(_ text: String, bold: Bool = false) {
            body.append(NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 14, weight: bold ? .semibold : .regular), .foregroundColor: KraftPaperView.ink]))
        }
        for (index, section) in analysis.displaySections.enumerated() {
            if index > 0 { append("\n\n") }
            append(section.heading + "\n", bold: true)
            append(section.text)
        }
        resultView.textStorage?.setAttributedString(body)
        resultView.scrollToBeginningOfDocument(nil)
        refresh()
    }

    func dismiss() {
        panel.orderOut(nil)
        onDismiss?()
    }

    @objc private func close() { dismiss() }
    @objc private func retry() { onRetry?() }
    @objc private func favorite() { onFavorite?() }
    @objc private func cancel() { onCancel?() }
    @objc private func settings() { dismiss(); onSettings?() }

    deinit {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
    }
}
