import Cocoa

struct Theme {
    static let windowBg = NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 0.75)
    static let headerBg = NSColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 0.85)
    static let chatBg = NSColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 0.70)
    static let inputBg = NSColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 0.88)
    static let inputFieldBg = NSColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1)

    static let userBubble = NSColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 0.95)
    static let aiBubble = NSColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 0.95)

    static let codeBg = NSColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1)
    static let codeHeader = NSColor(red: 0.16, green: 0.16, blue: 0.17, alpha: 1)
    static let codeText = NSColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1)
    static let codeLang = NSColor(white: 0.45, alpha: 1)

    static let textPrimary = NSColor(white: 0.90, alpha: 1)
    static let textSecondary = NSColor(white: 0.50, alpha: 1)
    static let textMuted = NSColor(white: 0.35, alpha: 1)

    static let statusActive = NSColor(red: 0.90, green: 0.60, blue: 0.20, alpha: 1)
    static let statusStealth = NSColor(red: 0.30, green: 0.65, blue: 0.40, alpha: 1)
    static let statusRecording = NSColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1)
}
