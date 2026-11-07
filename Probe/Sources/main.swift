import AppKit
import ApplicationServices

/// Own the native result, settings, and notebook windows for one menu-bar app.
final class AppController: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private let monitor = ForceClickMonitor()
    private let readerQueue = DispatchQueue(label: "com.selectenglish.selection")
    private let client = AnalysisClient()
    private let notebook = NotebookStore.applicationStore()
    private var resultWindow: NSWindow!
    private var settingsWindow: NSWindow!
    private var notebookWindow: NSWindow!
    private var diagnosticsWindow: NSWindow!
    private let sourceView = NSTextView()
    private let resultView = NSTextView()
    private let stateLabel = NSTextField(wrappingLabelWithString: "选中英文后，用力点按触控板即可翻译。")
    private let sourceLabel = NSTextField(wrappingLabelWithString: "原文")
    private let endpointField = NSTextField()
    private let modelField = NSTextField()
    private let keyField = NSSecureTextField()
    private let settingsState = NSTextField(wrappingLabelWithString: "")
    private let notebookPicker = NSPopUpButton(frame: .zero, pullsDown: false)
    private let notebookView = NSTextView()
    private let notebookState = NSTextField(wrappingLabelWithString: "")
    private let diagnosticsState = NSTextField(wrappingLabelWithString: "")
    private let diagnosticTarget = NSPopUpButton(frame: .zero, pullsDown: false)
    private var diagnosticTimer: Timer?
    private var lastCapture = "尚未读取选区"
    private var currentSource = ""
    private var currentAnalysis: Analysis?
    /// Invalidates AX and AI results after a newer trigger, cancel, or window close.
    private var generation = 0
    private var analysisTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        makeMenu()
        makeResultWindow()
        makeSettingsWindow()
        makeNotebookWindow()
        makeDiagnosticsWindow()
        monitor.onTrigger = { [weak self] app in self?.capture(app: app, automaticallyAnalyze: true) }
        monitor.onStatusChange = { [weak self] in self?.refreshDiagnostics() }
        monitor.start()
        diagnosticTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.diagnosticsWindow.isVisible else { return }
            self.refreshDiagnostics()
        }
        if let error = notebook.loadError { notebookState.stringValue = error }
        showResult()
    }

    private func makeMenu() {
        let mainMenu = NSMenu()
        let root = NSMenuItem()
        mainMenu.addItem(root)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "退出 SelectEnglish", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        root.submenu = appMenu
        let editRoot = NSMenuItem()
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editRoot.submenu = editMenu
        mainMenu.addItem(editRoot)
        NSApp.mainMenu = mainMenu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "译"
        statusItem.button?.toolTip = "SelectEnglish"
        let menu = NSMenu()
        for (title, action) in [("显示翻译", #selector(showResult)), ("AI 设置…", #selector(showSettings)),
                                ("我的收藏…", #selector(showNotebook)), ("触发与选区状态…", #selector(showDiagnostics))] {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: "")
            item.target = self
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 SelectEnglish", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    private func window(title: String, width: CGFloat, height: CGFloat) -> (NSWindow, NSStackView) {
        let result = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        result.title = title
        result.isReleasedWhenClosed = false
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        result.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: result.contentView!.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: result.contentView!.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: result.contentView!.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: result.contentView!.bottomAnchor, constant: -20)
        ])
        result.center()
        return (result, stack)
    }

    private func finishLayout(_ stack: NSStackView) {
        for child in stack.arrangedSubviews { child.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
    }

    private func scroll(_ view: NSTextView, height: CGFloat) -> NSScrollView {
        view.frame = NSRect(x: 0, y: 0, width: 650, height: height)
        view.isEditable = false
        view.isSelectable = true
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = false
        view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = true
        view.font = .systemFont(ofSize: 14)
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = view
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        scroll.setContentHuggingPriority(.defaultLow, for: .vertical)
        return scroll
    }

    private func buttons(_ entries: [(String, Selector)]) -> NSStackView {
        let row = NSStackView()
        row.spacing = 10
        for (title, action) in entries { row.addArrangedSubview(NSButton(title: title, target: self, action: action)) }
        return row
    }

    private func makeResultWindow() {
        let (window, stack) = window(title: "SelectEnglish · 翻译与表达", width: 760, height: 720)
        resultWindow = window
        window.delegate = self
        stack.addArrangedSubview(stateLabel)
        stack.addArrangedSubview(sourceLabel)
        stack.addArrangedSubview(scroll(sourceView, height: 110))
        stack.addArrangedSubview(NSTextField(labelWithString: "中文翻译与英文表达"))
        stack.addArrangedSubview(scroll(resultView, height: 280))
        stack.addArrangedSubview(buttons([("分析 / 重试", #selector(analyze)), ("取消", #selector(cancel)),
                                         ("收藏这次结果", #selector(saveFavorite)), ("我的收藏", #selector(showNotebook)),
                                         ("AI 设置", #selector(showSettings)), ("触发状态", #selector(showDiagnostics))]))
        finishLayout(stack)
    }

    private func makeSettingsWindow() {
        let (window, stack) = window(title: "SelectEnglish · AI 设置", width: 720, height: 410)
        settingsWindow = window
        window.delegate = self
        stack.addArrangedSubview(NSTextField(wrappingLabelWithString: "保存配置后，用力点按会把选中的文字发送到你指定的 AI 接口。未配置时只显示原文。密钥保存在系统钥匙串；同一服务留空可保留密钥，更换服务域名必须输入新密钥。"))
        stack.addArrangedSubview(NSTextField(labelWithString: "完整 HTTPS 接口地址（包含 /chat/completions）"))
        endpointField.placeholderString = "https://你的服务地址/v1/chat/completions"
        stack.addArrangedSubview(endpointField)
        stack.addArrangedSubview(NSTextField(labelWithString: "模型名称"))
        stack.addArrangedSubview(modelField)
        stack.addArrangedSubview(NSTextField(labelWithString: "API 密钥（只输入新密钥，不显示已保存密钥）"))
        keyField.placeholderString = "留空以保留已保存密钥"
        stack.addArrangedSubview(keyField)
        stack.addArrangedSubview(settingsState)
        stack.addArrangedSubview(buttons([("保存设置", #selector(saveSettings)), ("删除已保存密钥", #selector(deleteKey))]))
        finishLayout(stack)
    }

    private func makeNotebookWindow() {
        let (window, stack) = window(title: "SelectEnglish · 我的收藏", width: 760, height: 650)
        notebookWindow = window
        notebookPicker.target = self
        notebookPicker.action = #selector(selectFavorite)
        stack.addArrangedSubview(notebookPicker)
        stack.addArrangedSubview(notebookState)
        stack.addArrangedSubview(scroll(notebookView, height: 420))
        stack.addArrangedSubview(buttons([("删除选中收藏", #selector(deleteFavorite))]))
        finishLayout(stack)
    }

    private func makeDiagnosticsWindow() {
        let (window, stack) = window(title: "SelectEnglish · 触发与选区状态", width: 740, height: 360)
        diagnosticsWindow = window
        stack.addArrangedSubview(diagnosticsState)
        stack.addArrangedSubview(buttons([("授权辅助功能", #selector(authorize)), ("重新启动监听", #selector(restartMonitor))]))
        stack.addArrangedSubview(NSTextField(wrappingLabelWithString: "手动检查只读取指定应用，不自动发送 AI。全局重按始终读取触发时的前台应用。"))
        stack.addArrangedSubview(diagnosticTarget)
        stack.addArrangedSubview(buttons([("刷新应用", #selector(refreshTargets)), ("读取指定应用选区", #selector(readTarget))]))
        finishLayout(stack)
    }

    @objc private func showResult() { show(resultWindow) }
    @objc private func showSettings() {
        endpointField.stringValue = UserDefaults.standard.string(forKey: "ai.endpoint") ?? ""
        modelField.stringValue = UserDefaults.standard.string(forKey: "ai.model") ?? ""
        keyField.stringValue = ""
        do { settingsState.stringValue = try KeyStore.read() == nil ? "尚未保存密钥" : "钥匙串中已保存密钥" }
        catch { settingsState.stringValue = error.localizedDescription }
        show(settingsWindow)
    }
    @objc private func showNotebook() { refreshNotebook(); show(notebookWindow) }
    @objc private func showDiagnostics() { refreshTargets(); refreshDiagnostics(); show(diagnosticsWindow) }

    private func show(_ window: NSWindow) {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func saveSettings() {
        do {
            let configuration = AIConfiguration(endpoint: endpointField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                                                model: modelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
            _ = try configuration.validatedURL()
            let newKey = keyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if newKey.isEmpty && UserDefaults.standard.string(forKey: "ai.keyOrigin") != configuration.origin {
                throw AppError.message("更换 AI 服务时必须输入该服务的新密钥，不能复用旧服务密钥。")
            }
            if !newKey.isEmpty {
                try KeyStore.save(newKey)
                UserDefaults.standard.set(configuration.origin, forKey: "ai.keyOrigin")
            }
            UserDefaults.standard.set(configuration.endpoint, forKey: "ai.endpoint")
            UserDefaults.standard.set(configuration.model, forKey: "ai.model")
            keyField.stringValue = ""
            settingsState.stringValue = try KeyStore.read() == nil ? "地址和模型已保存，请再输入密钥。" : "已保存。下次重按或点击分析会向此接口发送原文。"
        } catch { settingsState.stringValue = error.localizedDescription }
    }

    @objc private func deleteKey() {
        do { try KeyStore.save(""); keyField.stringValue = ""; settingsState.stringValue = "已删除密钥，不会再自动请求 AI。" }
        catch { settingsState.stringValue = error.localizedDescription }
    }

    private func configuration() throws -> (AIConfiguration, String) {
        let configuration = AIConfiguration(endpoint: UserDefaults.standard.string(forKey: "ai.endpoint") ?? "",
                                            model: UserDefaults.standard.string(forKey: "ai.model") ?? "")
        _ = try configuration.validatedURL()
        guard UserDefaults.standard.string(forKey: "ai.keyOrigin") == configuration.origin else {
            throw AppError.message("此服务尚未绑定密钥，请在 AI 设置中重新输入并保存。")
        }
        guard let key = try KeyStore.read(), !key.isEmpty else { throw AppError.message("请先在 AI 设置中保存密钥。") }
        return (configuration, key)
    }

    /// Capture before opening the window. A newer action invalidates this AX result.
    private func capture(app: NSRunningApplication, automaticallyAnalyze: Bool) {
        invalidate()
        let requestGeneration = generation
        currentSource = ""
        currentAnalysis = nil
        sourceView.string = ""
        resultView.string = ""
        stateLabel.stringValue = "正在读取 \(app.localizedName ?? "目标应用") 的选区…"
        let pid = app.processIdentifier
        let launchDate = app.launchDate
        let name = app.localizedName ?? "目标应用"
        readerQueue.async { [weak self] in
            let result = SelectionReader.read(pid: pid, launchDate: launchDate)
            DispatchQueue.main.async {
                guard let self, self.generation == requestGeneration else { return }
                self.lastCapture = "\(name) · \(result.role) · \(result.message)"
                self.stateLabel.stringValue = result.message
                self.currentSource = result.text
                self.sourceView.string = result.text
                self.sourceLabel.stringValue = "原文 · \(name) · \(result.text.count) 字符"
                self.refreshDiagnostics()
                self.showResult()
                if automaticallyAnalyze && !result.text.isEmpty { self.analyze() }
            }
        }
    }

    /// Send only the current selected text to the user-configured service.
    @objc private func analyze() {
        invalidate()
        currentAnalysis = nil
        resultView.string = ""
        guard !currentSource.isEmpty else { stateLabel.stringValue = "请先在其他应用选中英文，再用力点按。"; return }
        guard currentSource.count <= 20_000 else { stateLabel.stringValue = "原文超过 20,000 个字符，请缩短选区。"; return }
        let settings: (AIConfiguration, String)
        do { settings = try configuration() }
        catch { stateLabel.stringValue = "原文已读取；\(error.localizedDescription)"; return }
        let requestGeneration = generation
        let text = currentSource
        stateLabel.stringValue = "正在翻译并整理表达…可点击取消。"
        analysisTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await self.client.analyze(text: text, configuration: settings.0, key: settings.1)
                guard self.generation == requestGeneration, !Task.isCancelled else { return }
                self.currentAnalysis = result
                self.resultView.string = result.displayText
                self.stateLabel.stringValue = "完成。可收藏到本机。"
            } catch {
                guard self.generation == requestGeneration, !Task.isCancelled else { return }
                if let network = error as? URLError, network.code == .timedOut {
                    self.stateLabel.stringValue = "请求超时（60 秒），请重试。"
                } else { self.stateLabel.stringValue = "分析失败：\(error.localizedDescription)" }
            }
            if self.generation == requestGeneration { self.analysisTask = nil }
        }
    }

    private func invalidate() {
        generation += 1
        analysisTask?.cancel()
        analysisTask = nil
    }

    @objc private func cancel() { invalidate(); stateLabel.stringValue = "已取消，点击分析可重试。" }
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === resultWindow { invalidate() }
        if notification.object as? NSWindow === settingsWindow { keyField.stringValue = "" }
    }

    @objc private func saveFavorite() {
        guard let result = currentAnalysis else { stateLabel.stringValue = "分析完成后才能收藏。"; return }
        do { try notebook.save(source: currentSource, analysis: result); stateLabel.stringValue = "已收藏到本机。" }
        catch { stateLabel.stringValue = error.localizedDescription }
    }

    private func refreshNotebook() {
        notebookPicker.removeAllItems()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        for entry in notebook.entries {
            let item = NSMenuItem(title: "\(formatter.string(from: entry.createdAt)) · \(entry.source.prefix(55).replacingOccurrences(of: "\n", with: " "))", action: nil, keyEquivalent: "")
            notebookPicker.menu!.addItem(item)
        }
        if !notebook.entries.isEmpty { notebookPicker.selectItem(at: 0) }
        notebookState.stringValue = notebook.loadError ?? "共 \(notebook.entries.count) 条，仅保存在本机。"
        selectFavorite()
    }

    @objc private func selectFavorite() {
        let index = notebookPicker.indexOfSelectedItem
        guard notebook.entries.indices.contains(index) else { notebookView.string = "尚无收藏。"; return }
        let entry = notebook.entries[index]
        notebookView.string = "原文\n\(entry.source)\n\n\(entry.analysis.displayText)"
    }

    @objc private func deleteFavorite() {
        let index = notebookPicker.indexOfSelectedItem
        guard notebook.entries.indices.contains(index) else { return }
        do { try notebook.delete(id: notebook.entries[index].id); refreshNotebook() }
        catch { notebookState.stringValue = error.localizedDescription }
    }

    private func refreshDiagnostics() {
        diagnosticsState.stringValue = "辅助功能：\(AXIsProcessTrusted() ? "已授权" : "未授权")\n全局监听：\(monitor.isEnabled ? "已启用" : "未启用，请授权后重新启动监听")\n原始手势：\(monitor.rawGestures)  压力：\(monitor.pressureEvents)  stage 2：\(monitor.stage2Events)  触发：\(monitor.triggers)\n最近选区：\(lastCapture)"
    }
    @objc private func authorize() {
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
        refreshDiagnostics()
    }
    @objc private func restartMonitor() { monitor.start(); refreshDiagnostics() }
    @objc private func refreshTargets() {
        let previous = diagnosticTarget.selectedItem?.tag
        diagnosticTarget.removeAllItems()
        for app in NSWorkspace.shared.runningApplications.filter({ $0.activationPolicy == .regular && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }).sorted(by: { ($0.localizedName ?? "") < ($1.localizedName ?? "") }) {
            diagnosticTarget.addItem(withTitle: app.localizedName ?? "未知应用")
            diagnosticTarget.lastItem!.tag = Int(app.processIdentifier)
        }
        if let previous { diagnosticTarget.selectItem(withTag: previous) }
    }
    @objc private func readTarget() {
        guard let item = diagnosticTarget.selectedItem, let app = NSRunningApplication(processIdentifier: pid_t(item.tag)) else { return }
        capture(app: app, automaticallyAnalyze: false)
    }

    func applicationDidBecomeActive(_ notification: Notification) { refreshDiagnostics() }
    func applicationWillTerminate(_ notification: Notification) { invalidate(); diagnosticTimer?.invalidate(); monitor.stop() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

let app = NSApplication.shared
let controller = AppController()
app.delegate = controller
app.run()
