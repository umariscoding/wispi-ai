import Cocoa

struct Theme {
    // Glassmorphism background
    static let windowBg = NSColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 0.60)
    static let headerBg = NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 0.40)
    static let chatBg = NSColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 0.30)
    static let inputBg = NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 0.50)

    // Frosted glass input field
    static let inputFieldBg = NSColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.35)

    // Bubble colors with transparency
    static let userBubble = NSColor(red: 0.25, green: 0.55, blue: 0.98, alpha: 0.85)
    static let aiBubble = NSColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 0.50)

    static let codeBg = NSColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 0.80)
    static let codeHeader = NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 0.60)
    static let codeText = NSColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    static let codeLang = NSColor(white: 0.50, alpha: 0.8)

    static let textPrimary = NSColor(white: 0.95, alpha: 1)
    static let textSecondary = NSColor(white: 0.55, alpha: 1)
    static let textMuted = NSColor(white: 0.45, alpha: 0.8)

    static let statusActive = NSColor(red: 0.95, green: 0.65, blue: 0.25, alpha: 1)
    static let statusStealth = NSColor(red: 0.35, green: 0.70, blue: 0.45, alpha: 1)
    static let statusRecording = NSColor(red: 0.98, green: 0.30, blue: 0.30, alpha: 1)
}
