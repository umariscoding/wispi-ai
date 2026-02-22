import Cocoa
import QuartzCore

class ChatController: NSViewController, NSTextFieldDelegate {
    private let scrollView = NSScrollView()
    private let chatContainer = FlippedView()
    private let inputField = NSTextField()
    private let statusDot = NSView()
    private let hintLabel = NSTextField()
    private let client = OpenAIClient()
    private let audioRecorder = AudioRecorder()

    private var messageData: [MessageData] = []
    private var messageViews: [NSView] = []
    private var isLoading = false
    private var isRecordingAudio = false
    var onExit: (() -> Void)?
    var onRecordingStateChange: ((Bool) -> Void)?

    private var queuedScreenshots: [Data] = []
    var onScreenshotQueueChange: ((Int) -> Void)?

    var currentHeight: CGFloat = WINDOW_HEIGHT
    var currentWidth: CGFloat = WINDOW_WIDTH

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: WINDOW_WIDTH, height: WINDOW_HEIGHT))
        view.wantsLayer = true
        view.layer?.backgroundColor = Theme.windowBg.cgColor
        setupUI()
    }

    func updateLayout(height: CGFloat) {
        updateLayout(width: WINDOW_WIDTH, height: height)
    }

    func updateLayout(width: CGFloat, height: CGFloat) {
        let widthChanged = (width != currentWidth)
        currentHeight = height
        currentWidth = width
        view.frame.size = NSSize(width: width, height: height)

        if let header = view.subviews.first(where: { $0.frame.origin.y > height - 50 }) {
            header.frame = NSRect(x: 0, y: height - 36, width: width, height: 36)
            header.subviews.forEach { v in
                if let tf = v as? NSTextField, tf.alignment == .right {
                    tf.frame = NSRect(x: width - 190, y: 10, width: 180, height: 14)
                }
            }
        }

        if let inputArea = view.subviews.first(where: { $0.frame.origin.y == 0 && $0.frame.height == 48 }) {
            inputArea.frame = NSRect(x: 0, y: 0, width: width, height: 48)
            inputArea.subviews.forEach { v in
                if v.layer?.cornerRadius == 15 {
                    v.frame = NSRect(x: 8, y: 9, width: width - 16, height: 30)
                    v.subviews.forEach { tf in
                        if let textField = tf as? NSTextField {
                            textField.frame = NSRect(x: 12, y: 5, width: width - 40, height: 20)
                        }
                    }
                }
            }
        }

        scrollView.frame = NSRect(x: 0, y: 48, width: width, height: height - 36 - 48)

        if widthChanged {
            rebuildMessages()
        } else {
            layoutMessages()
        }
    }

    private func rebuildMessages() {
        for view in messageViews {
            view.removeFromSuperview()
        }
        messageViews.removeAll()

        for data in messageData {
            let msgView = MessageView(text: data.text, isUser: data.isUser, width: currentWidth)
            messageViews.append(msgView)
            chatContainer.addSubview(msgView)
        }

        layoutMessages()
    }

    private func setupUI() {
        let header = NSView(frame: NSRect(x: 0, y: WINDOW_HEIGHT - 36, width: WINDOW_WIDTH, height: 36))
        header.wantsLayer = true
        header.layer?.backgroundColor = Theme.headerBg.cgColor
        view.addSubview(header)

        statusDot.frame = NSRect(x: 10, y: 14, width: 7, height: 7)
        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 3.5
        statusDot.layer?.backgroundColor = Theme.statusStealth.cgColor
        header.addSubview(statusDot)

        let title = NSTextField(labelWithString: APP_NAME)
        title.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        title.textColor = Theme.textSecondary
        title.frame = NSRect(x: 22, y: 10, width: 90, height: 14)
        header.addSubview(title)

        hintLabel.font = NSFont.monospacedSystemFont(ofSize: 8, weight: .regular)
        hintLabel.textColor = Theme.textMuted
        hintLabel.alignment = .right
        hintLabel.frame = NSRect(x: WINDOW_WIDTH - 190, y: 10, width: 180, height: 14)
        header.addSubview(hintLabel)

        let inputArea = NSView(frame: NSRect(x: 0, y: 0, width: WINDOW_WIDTH, height: 48))
        inputArea.wantsLayer = true
        inputArea.layer?.backgroundColor = Theme.inputBg.cgColor
        view.addSubview(inputArea)

        let fieldBg = NSView(frame: NSRect(x: 8, y: 9, width: WINDOW_WIDTH - 16, height: 30))
        fieldBg.wantsLayer = true
        fieldBg.layer?.cornerRadius = 15
        fieldBg.layer?.backgroundColor = Theme.inputFieldBg.cgColor
        inputArea.addSubview(fieldBg)

        inputField.frame = NSRect(x: 12, y: 5, width: WINDOW_WIDTH - 40, height: 20)
        inputField.isBordered = false
        inputField.focusRingType = .none
        inputField.backgroundColor = .clear
        inputField.font = NSFont.systemFont(ofSize: 12)
        inputField.textColor = Theme.textPrimary
        inputField.placeholderString = "Message..."
        inputField.delegate = self
        (inputField.cell as? NSTextFieldCell)?.placeholderAttributedString = NSAttributedString(
            string: "Message...", attributes: [.foregroundColor: Theme.textMuted, .font: NSFont.systemFont(ofSize: 12)])
        fieldBg.addSubview(inputField)

        scrollView.frame = NSRect(x: 0, y: 48, width: WINDOW_WIDTH, height: WINDOW_HEIGHT - 36 - 48)
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = Theme.chatBg
        scrollView.borderType = .noBorder

        chatContainer.wantsLayer = true
        chatContainer.layer?.backgroundColor = Theme.chatBg.cgColor
        scrollView.documentView = chatContainer
        view.addSubview(scrollView)

        updateMode(active: false)
        addMessage("Ready.\n\n⌥Space type • ⌥S screen • ⌥R record\n⌥A queue • ⌥Enter send • ⌥W wide • ⌥F tall\n⌥T transparent • ⌥H hide • ⌥C clear • ⌥1-5 position", isUser: false)
    }

    func updateMode(active: Bool) {
        if isRecordingAudio {
            statusDot.layer?.backgroundColor = Theme.statusRecording.cgColor
            hintLabel.stringValue = "🔴 Recording... ⌥R stop"
        } else if !queuedScreenshots.isEmpty {
            statusDot.layer?.backgroundColor = NSColor(red: 0.40, green: 0.60, blue: 0.95, alpha: 1).cgColor
            let count = queuedScreenshots.count
            hintLabel.stringValue = "📸 \(count) screenshot\(count > 1 ? "s" : "") • ⌥Enter to send"

            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1.0
            pulse.toValue = 0.5
            pulse.duration = 0.6
            pulse.autoreverses = true
            pulse.repeatCount = 1
            statusDot.layer?.add(pulse, forKey: "pulse")
        } else {
            statusDot.layer?.backgroundColor = active ? Theme.statusActive.cgColor : Theme.statusStealth.cgColor
            hintLabel.stringValue = active ? "⌥Space hide" : "⌥Space show"
        }
    }

    func focus() { view.window?.makeFirstResponder(inputField) }

    func scrollUp() {
        let current = scrollView.contentView.bounds.origin.y
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: max(0, current - 100)))
    }

    func scrollDown() {
        let current = scrollView.contentView.bounds.origin.y
        let maxY = max(0, chatContainer.frame.height - scrollView.frame.height)
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: min(maxY, current + 100)))
    }

    func clear() {
        messageData.removeAll()
        messageViews.forEach { $0.removeFromSuperview() }
        messageViews.removeAll()
        client.clear()
        queuedScreenshots.removeAll()
        layoutMessages()
        addMessage("Cleared.", isUser: false)
        updateMode(active: true)
    }

    func getInputText() -> String {
        return inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func clearInput() {
        inputField.stringValue = ""
    }

    private var loadingView: NSView?

    func captureAndSend(prompt: String = "") {
        guard !isLoading else { return }

        addMessage(prompt.isEmpty ? "[📷 Capturing screen...]" : "[📷 Screen] \(prompt)", isUser: true)

        isLoading = true
        let loading = LoadingView()
        loadingView = loading
        chatContainer.addSubview(loading)
        layoutMessages()

        ScreenCapture.captureScreen { [weak self] result in
            guard let self = self else { return }

            self.loadingView?.removeFromSuperview()
            self.loadingView = nil

            switch result {
            case .success(let imageData):
                let apiLoading = LoadingView()
                self.loadingView = apiLoading
                self.chatContainer.addSubview(apiLoading)
                self.layoutMessages()

                self.client.sendWithScreenshot(prompt, imageData: imageData) { [weak self] response in
                    self?.loadingView?.removeFromSuperview()
                    self?.loadingView = nil
                    self?.addMessage(response, isUser: false)
                    self?.isLoading = false
                }

            case .failure(let error):
                switch error {
                case .noPermission(let details):
                    self.addMessage("Permission error: \(details)\n\nTry: Remove app from System Settings, re-add it, then RESTART.", isUser: false)
                case .noDisplay:
                    self.addMessage("No display found for capture.", isUser: false)
                case .captureFailed(let msg):
                    self.addMessage("Capture failed: \(msg)", isUser: false)
                }
                self.isLoading = false
            }
        }
    }

    func queueScreenshot() {
        guard !isLoading else { return }

        ScreenCapture.captureScreen { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let imageData):
                self.queuedScreenshots.append(imageData)
                self.updateMode(active: true)
                self.onScreenshotQueueChange?(self.queuedScreenshots.count)

            case .failure(let error):
                switch error {
                case .noPermission(let msg):
                    self.addMessage("⚠️ Screen recording permission needed\n\n\(msg)", isUser: false)
                    ScreenCapture.requestPermission()
                case .noDisplay:
                    self.addMessage("⚠️ No display found", isUser: false)
                case .captureFailed(let msg):
                    self.addMessage("⚠️ Capture failed: \(msg)", isUser: false)
                }
            }
        }
    }

    func sendQueuedScreenshots() {
        guard !queuedScreenshots.isEmpty else {
            addMessage("No screenshots queued. Use ⌥A to add screenshots first.", isUser: false)
            return
        }

        guard !isLoading else { return }

        let prompt = getInputText()
        let count = queuedScreenshots.count
        let screenshots = queuedScreenshots

        queuedScreenshots.removeAll()
        clearInput()
        updateMode(active: true)
        onScreenshotQueueChange?(0)

        let displayPrompt = prompt.isEmpty ? "" : " \(prompt)"
        addMessage("[📸 \(count) Screenshots]\(displayPrompt)", isUser: true)

        isLoading = true
        let loading = LoadingView()
        loadingView = loading
        chatContainer.addSubview(loading)
        layoutMessages()

        client.sendWithMultipleScreenshots(prompt, imageDataArray: screenshots) { [weak self] response in
            guard let self = self else { return }
            self.loadingView?.removeFromSuperview()
            self.loadingView = nil
            self.addMessage(response, isUser: false)
            self.isLoading = false
        }
    }

    func toggleRecording() {
        if isRecordingAudio {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard !isLoading, !isRecordingAudio else { return }

        isRecordingAudio = true
        onRecordingStateChange?(true)
        updateMode(active: true)
        addMessage("[🎙️ Recording audio... Press ⌥R to stop]", isUser: true)

        audioRecorder.startRecording { [weak self] result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self?.isRecordingAudio = false
                    self?.onRecordingStateChange?(false)
                    self?.addMessage("Recording error: \(error.localizedDescription)", isUser: false)
                }
            }
        }
    }

    private func stopRecording() {
        guard isRecordingAudio else { return }

        isRecordingAudio = false
        onRecordingStateChange?(false)
        updateMode(active: true)

        addMessage("[⏹️ Processing recording...]", isUser: true)

        isLoading = true
        let loading = LoadingView()
        loadingView = loading
        chatContainer.addSubview(loading)
        layoutMessages()

        audioRecorder.stopRecording()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            let tempDir = FileManager.default.temporaryDirectory
            let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey])
            let audioFile = files?
                .filter { $0.pathExtension == "m4a" }
                .sorted { (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast >
                         (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast }
                .first

            guard let fileURL = audioFile else {
                self.loadingView?.removeFromSuperview()
                self.loadingView = nil
                self.addMessage("No recording file found.", isUser: false)
                self.isLoading = false
                return
            }

            self.client.transcribeAudio(fileURL: fileURL) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let transcription):
                    try? FileManager.default.removeItem(at: fileURL)

                    self.addMessage("**Heard:** \(transcription)", isUser: true)

                    self.client.send("The user said (from audio): \"\(transcription)\"\n\nRespond to what they said or asked.") { [weak self] response in
                        self?.loadingView?.removeFromSuperview()
                        self?.loadingView = nil
                        self?.addMessage(response, isUser: false)
                        self?.isLoading = false
                    }

                case .failure(let error):
                    self.loadingView?.removeFromSuperview()
                    self.loadingView = nil
                    self.addMessage("Transcription error: \(error.localizedDescription)", isUser: false)
                    self.isLoading = false
                }
            }
        }
    }

    var isRecording: Bool { isRecordingAudio }

    func addMessage(_ text: String, isUser: Bool) {
        messageData.append(MessageData(text: text, isUser: isUser))
        let msg = MessageView(text: text, isUser: isUser, width: currentWidth)
        messageViews.append(msg)
        chatContainer.addSubview(msg)
        layoutMessages()
    }

    private func layoutMessages() {
        var y: CGFloat = 8
        for m in messageViews {
            m.frame.origin = NSPoint(x: 0, y: y)
            y += m.frame.height + 10
        }

        if let loading = loadingView {
            loading.frame.origin = NSPoint(x: 0, y: y)
            y += loading.frame.height + 10
        }

        let h = max(y, scrollView.frame.height)
        chatContainer.frame = NSRect(x: 0, y: 0, width: currentWidth, height: h)

        DispatchQueue.main.async {
            let scrollY = max(0, h - self.scrollView.frame.height)
            self.scrollView.contentView.scroll(to: NSPoint(x: 0, y: scrollY))
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy sel: Selector) -> Bool {
        if let event = NSApp.currentEvent,
           event.modifierFlags.contains(.option) && event.keyCode == 36 {
            sendQueuedScreenshots()
            return true
        }

        switch sel {
        case #selector(insertNewline(_:)): send(); return true
        case #selector(cancelOperation(_:)): onExit?(); return true
        default: return false
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.option) && event.keyCode == 36 {
            sendQueuedScreenshots()
            return
        }
        super.keyDown(with: event)
    }

    private func send() {
        let text = getInputText()
        guard !text.isEmpty, !isLoading else { return }

        addMessage(text, isUser: true)
        clearInput()

        isLoading = true
        let loading = LoadingView()
        loadingView = loading
        chatContainer.addSubview(loading)
        layoutMessages()

        client.send(text) { [weak self] response in
            guard let self = self else { return }
            self.loadingView?.removeFromSuperview()
            self.loadingView = nil
            self.addMessage(response, isUser: false)
            self.isLoading = false
            self.onExit?()
        }
    }
}
