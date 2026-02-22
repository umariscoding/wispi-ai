import Cocoa

class CodeBlockView: NSView {
    override var isFlipped: Bool { true }

    init(code: String, language: String, width: CGFloat) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        layer?.backgroundColor = Theme.codeBg.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(white: 0.15, alpha: 1).cgColor

        let blockWidth = width - 20
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines)

        let header = NSView(frame: NSRect(x: 0, y: 0, width: blockWidth, height: 26))
        header.wantsLayer = true
        header.layer?.backgroundColor = Theme.codeHeader.cgColor

        let langLabel = NSTextField(labelWithString: language.isEmpty ? "code" : language.lowercased())
        langLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
        langLabel.textColor = Theme.codeLang
        langLabel.frame = NSRect(x: 10, y: 6, width: 150, height: 14)
        header.addSubview(langLabel)
        addSubview(header)

        let codeView = NSTextView()
        codeView.string = cleanCode
        codeView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        codeView.textColor = Theme.codeText
        codeView.backgroundColor = Theme.codeBg
        codeView.isEditable = false
        codeView.isSelectable = true
        codeView.isVerticallyResizable = false
        codeView.isHorizontallyResizable = false
        codeView.textContainerInset = NSSize(width: 10, height: 8)
        codeView.textContainer?.lineFragmentPadding = 0
        codeView.textContainer?.widthTracksTextView = false
        codeView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        let lineCount = cleanCode.components(separatedBy: "\n").count
        let codeHeight = CGFloat(lineCount) * 15 + 20

        let lines = cleanCode.components(separatedBy: "\n")
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        var maxLineWidth: CGFloat = blockWidth - 20
        for line in lines {
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let lineWidth = (line as NSString).size(withAttributes: attrs).width + 30
            maxLineWidth = max(maxLineWidth, lineWidth)
        }

        codeView.frame = NSRect(x: 0, y: 0, width: maxLineWidth, height: codeHeight)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = Theme.codeBg
        scrollView.drawsBackground = true
        scrollView.documentView = codeView
        scrollView.frame = NSRect(x: 0, y: 26, width: blockWidth, height: codeHeight)
        addSubview(scrollView)

        frame = NSRect(x: 10, y: 0, width: blockWidth, height: codeHeight + 26)
    }
    required init?(coder: NSCoder) { fatalError() }
}
