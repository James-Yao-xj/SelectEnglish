import AppKit

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
        let material = NSVisualEffectView()
        material.material = .popover
        material.blendingMode = .behindWindow
        material.state = .active
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
        sourceLabel.textColor = .secondaryLabelColor
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
        sourceView.textColor = .secondaryLabelColor
        sourceScroll.heightAnchor.constraint(equalToConstant: 48).isActive = true
        stack.addArrangedSubview(sourceScroll)
        stateLabel.font = .systemFont(ofSize: 12)
        stateLabel.textColor = .secondaryLabelColor
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
            guard let self, self.panel.isVisible else { return event }
            if event.type == .keyDown {
                if event.keyCode == 53 { self.dismiss(); return nil }
            } else if !self.panel.frame.contains(NSEvent.mouseLocation) { self.dismiss() }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.panel.isVisible, !self.panel.frame.contains(NSEvent.mouseLocation) else { return }
            self.dismiss()
        }
    }

    private func configure(_ view: NSTextView, in scroll: NSScrollView) {
        view.frame = NSRect(x: 0, y: 0, width: 388, height: 50)
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
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
            body.append(NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 14, weight: bold ? .semibold : .regular), .foregroundColor: NSColor.labelColor]))
        }
        append("中文翻译\n", bold: true)
        append(analysis.translation + "\n\n")
        append("英文表达\n", bold: true)
        if analysis.expressions.isEmpty { append("这段原文没有适合单独积累的表达。") }
        for entry in analysis.expressions {
            append("\n" + entry.phrase + "\n", bold: true)
            append(entry.meaning + "\n" + entry.usage + "\n例句：" + entry.example + "\n")
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
