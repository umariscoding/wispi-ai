import Cocoa

class StealthPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func setupStealth() {
        sharingType = .none
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow)))
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isExcludedFromWindowsMenu = true
        hidesOnDeactivate = false
        ignoresMouseEvents = true
    }

    func setActive(_ on: Bool, transparencyLevel: Int = 0) {
        let alpha: CGFloat
        switch transparencyLevel {
        case 0: alpha = on ? 0.94 : 0.82
        case 1: alpha = on ? 0.70 : 0.55
        case 2: alpha = on ? 0.45 : 0.30
        default: alpha = on ? 0.94 : 0.82
        }
        alphaValue = alpha
    }
}
