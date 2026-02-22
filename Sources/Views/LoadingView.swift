import Cocoa

class LoadingView: FlippedView {
    init() {
        super.init(frame: NSRect(x: 10, y: 0, width: 48, height: 28))
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.backgroundColor = Theme.aiBubble.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(white: 0.20, alpha: 1).cgColor

        let dots = NSTextField(labelWithString: "•••")
        dots.font = NSFont.systemFont(ofSize: 12)
        dots.textColor = Theme.textMuted
        dots.frame = NSRect(x: 10, y: 5, width: 30, height: 18)
        addSubview(dots)
    }
    required init?(coder: NSCoder) { fatalError() }
}
