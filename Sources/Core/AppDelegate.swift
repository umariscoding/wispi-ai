import Cocoa
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: StealthPanel!
    var chat: ChatController!
    var hk: HotkeyManager!
    var active = false
    var prevApp: NSRunningApplication?
    var hidden = false
    var isFullHeight = false
    var isWideMode = false
    var transparencyLevel = 0

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupPanel()
        setupHotkeys()
    }

    func setupPanel() {
        let s = NSScreen.main!.visibleFrame
        panel = StealthPanel(
            contentRect: NSRect(x: s.maxX - WINDOW_WIDTH - 12, y: s.maxY - WINDOW_HEIGHT - 12,
                                width: WINDOW_WIDTH, height: WINDOW_HEIGHT),
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = Theme.windowBg
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.setupStealth()
        panel.setActive(false)

        chat = ChatController()
        chat.onExit = { [weak self] in self?.deactivate() }
        panel.contentViewController = chat
        panel.orderFrontRegardless()
    }

    func setupHotkeys() {
        hk = HotkeyManager()
        let opt = UInt32(optionKey)

        hk.add(key: kVK_Space, mod: opt, id: 1) { [weak self] in self?.toggle() }
        hk.add(key: kVK_ANSI_H, mod: opt, id: 2) { [weak self] in self?.toggleHide() }
        hk.add(key: kVK_ANSI_C, mod: opt, id: 3) { [weak self] in self?.chat.clear() }
        hk.add(key: kVK_ANSI_S, mod: opt, id: 4) { [weak self] in self?.captureScreen() }
        hk.add(key: kVK_ANSI_F, mod: opt, id: 5) { [weak self] in self?.toggleFullHeight() }
        hk.add(key: kVK_ANSI_W, mod: opt, id: 6) { [weak self] in self?.toggleWidth() }
        hk.add(key: kVK_ANSI_T, mod: opt, id: 7) { [weak self] in self?.toggleTransparency() }
        hk.add(key: kVK_ANSI_R, mod: opt, id: 8) { [weak self] in self?.toggleRecording() }
        hk.add(key: kVK_ANSI_A, mod: opt, id: 9) { [weak self] in self?.queueScreenshot() }
        hk.add(key: kVK_ANSI_1, mod: opt, id: 10) { [weak self] in self?.move(.topLeft) }
        hk.add(key: kVK_ANSI_2, mod: opt, id: 11) { [weak self] in self?.move(.topCenter) }
        hk.add(key: kVK_ANSI_3, mod: opt, id: 12) { [weak self] in self?.move(.topRight) }
        hk.add(key: kVK_ANSI_4, mod: opt, id: 13) { [weak self] in self?.move(.bottomLeft) }
        hk.add(key: kVK_ANSI_5, mod: opt, id: 14) { [weak self] in self?.move(.bottomRight) }
        hk.add(key: kVK_UpArrow, mod: opt, id: 20) { [weak self] in if self?.active == true { self?.chat.scrollUp() } }
        hk.add(key: kVK_DownArrow, mod: opt, id: 21) { [weak self] in if self?.active == true { self?.chat.scrollDown() } }
        hk.start()
    }

    func toggleFullHeight() {
        let s = NSScreen.main!.visibleFrame
        let currentFrame = panel.frame

        if isFullHeight {
            let newHeight = WINDOW_HEIGHT
            let newY = currentFrame.origin.y + currentFrame.height - newHeight
            panel.setFrame(NSRect(x: currentFrame.origin.x, y: max(s.minY, newY), width: WINDOW_WIDTH, height: newHeight), display: true, animate: true)
            chat.updateLayout(height: newHeight)
            isFullHeight = false
        } else {
            let newHeight = s.height - 20
            panel.setFrame(NSRect(x: currentFrame.origin.x, y: s.minY + 10, width: WINDOW_WIDTH, height: newHeight), display: true, animate: true)
            chat.updateLayout(height: newHeight)
            isFullHeight = true
        }
    }

    func toggleWidth() {
        let s = NSScreen.main!.visibleFrame
        let currentFrame = panel.frame

        if isWideMode {
            WINDOW_WIDTH = WINDOW_WIDTH_NARROW
            isWideMode = false
        } else {
            WINDOW_WIDTH = WINDOW_WIDTH_WIDE
            isWideMode = true
        }

        let newX = currentFrame.maxX - WINDOW_WIDTH
        let h = isFullHeight ? s.height - 20 : currentFrame.height

        panel.setFrame(NSRect(x: max(s.minX, newX), y: currentFrame.origin.y, width: WINDOW_WIDTH, height: h), display: true, animate: true)
        chat.updateLayout(width: WINDOW_WIDTH, height: h)
    }

    func toggleTransparency() {
        transparencyLevel = (transparencyLevel + 1) % 3

        let alpha: CGFloat
        switch transparencyLevel {
        case 0: alpha = active ? 0.94 : 0.82
        case 1: alpha = active ? 0.70 : 0.55
        case 2: alpha = active ? 0.45 : 0.30
        default: alpha = 0.82
        }

        panel.alphaValue = alpha
    }

    func toggleRecording() {
        if hidden { panel.orderFrontRegardless(); hidden = false }
        if !active { activate() }

        chat.toggleRecording()
    }

    enum Pos { case topLeft, topCenter, topRight, bottomLeft, bottomRight }
    func move(_ p: Pos) {
        let s = NSScreen.main!.visibleFrame
        let m: CGFloat = 12
        let h = isFullHeight ? s.height - 20 : WINDOW_HEIGHT
        var x: CGFloat, y: CGFloat
        switch p {
        case .topLeft: x = s.minX + m; y = s.maxY - h - m
        case .topCenter: x = s.midX - WINDOW_WIDTH / 2; y = s.maxY - h - m
        case .topRight: x = s.maxX - WINDOW_WIDTH - m; y = s.maxY - h - m
        case .bottomLeft: x = s.minX + m; y = s.minY + m
        case .bottomRight: x = s.maxX - WINDOW_WIDTH - m; y = s.minY + m
        }
        panel.setFrame(NSRect(x: x, y: y, width: WINDOW_WIDTH, height: h), display: true, animate: true)
    }

    func toggleHide() {
        if hidden { panel.orderFrontRegardless(); hidden = false }
        else { panel.orderOut(nil); hidden = true; if active { deactivate() } }
    }

    func captureScreen() {
        let prompt = chat.getInputText()
        if !prompt.isEmpty { chat.clearInput() }

        if hidden { panel.orderFrontRegardless(); hidden = false }
        if !active { activate() }

        chat.captureAndSend(prompt: prompt)
    }

    func queueScreenshot() {
        if hidden { panel.orderFrontRegardless(); hidden = false }
        if !active { activate() }

        chat.queueScreenshot()
    }

    func toggle() {
        if hidden { panel.orderFrontRegardless(); hidden = false }
        active ? deactivate() : activate()
    }

    func activate() {
        active = true
        prevApp = NSWorkspace.shared.frontmostApplication
        panel.setActive(true, transparencyLevel: transparencyLevel)
        chat.updateMode(active: true)
        panel.makeKeyAndOrderFront(nil)
        chat.focus()
    }

    func deactivate() {
        active = false
        panel.setActive(false, transparencyLevel: transparencyLevel)
        chat.updateMode(active: false)
        panel.resignKey()
        prevApp?.activate(options: [])
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
