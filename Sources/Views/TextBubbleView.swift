import Cocoa

class TextBubbleView: NSView {
    override var isFlipped: Bool { true }

    init(text: String, isUser: Bool, width: CGFloat) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 12

        let maxWidth = width - 50

        let textView = NSTextView()

        if isUser {
            textView.string = text
            textView.font = NSFont.systemFont(ofSize: 12.5)
            textView.textColor = Theme.textPrimary
        } else {
            textView.textStorage?.setAttributedString(Self.parseMarkdown(text))
        }

        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 10, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.frame = NSRect(x: 0, y: 0, width: maxWidth - 20, height: 10000)
        textView.sizeToFit()

        let bubbleWidth = min(maxWidth, textView.frame.width + 24)
        let bubbleHeight = textView.frame.height + 4

        if isUser {
            layer?.backgroundColor = Theme.userBubble.cgColor
            frame = NSRect(x: width - bubbleWidth - 10, y: 0, width: bubbleWidth, height: bubbleHeight)
        } else {
            layer?.backgroundColor = Theme.aiBubble.cgColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor(white: 0.20, alpha: 1).cgColor
            frame = NSRect(x: 10, y: 0, width: bubbleWidth, height: bubbleHeight)
        }

        textView.frame = bounds
        addSubview(textView)
    }
    required init?(coder: NSCoder) { fatalError() }

    static func parseMarkdown(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let baseFont = NSFont.systemFont(ofSize: 12.5)
        let boldFont = NSFont.boldSystemFont(ofSize: 12.5)
        let headerFont = NSFont.boldSystemFont(ofSize: 14)
        let codeFont = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .regular)

        let lines = text.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            var processedLine = line
            var lineAttrs: [NSAttributedString.Key: Any] = [
                .font: baseFont,
                .foregroundColor: Theme.textPrimary
            ]

            if processedLine.hasPrefix("### ") {
                processedLine = String(processedLine.dropFirst(4))
                lineAttrs[.font] = headerFont
            } else if processedLine.hasPrefix("## ") {
                processedLine = String(processedLine.dropFirst(3))
                lineAttrs[.font] = headerFont
            } else if processedLine.hasPrefix("# ") {
                processedLine = String(processedLine.dropFirst(2))
                lineAttrs[.font] = NSFont.boldSystemFont(ofSize: 15)
            } else if processedLine.hasPrefix("- ") || processedLine.hasPrefix("* ") {
                processedLine = "• " + String(processedLine.dropFirst(2))
            }

            let attrLine = parseInlineMarkdown(processedLine, baseAttrs: lineAttrs, boldFont: boldFont, codeFont: codeFont)
            result.append(attrLine)

            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: lineAttrs))
            }
        }

        return result
    }

    static func parseInlineMarkdown(_ text: String, baseAttrs: [NSAttributedString.Key: Any], boldFont: NSFont, codeFont: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var remaining = text

        while !remaining.isEmpty {
            if let boldStart = remaining.range(of: "**") {
                let before = String(remaining[..<boldStart.lowerBound])
                if !before.isEmpty {
                    result.append(NSAttributedString(string: before, attributes: baseAttrs))
                }

                remaining = String(remaining[boldStart.upperBound...])

                if let boldEnd = remaining.range(of: "**") {
                    let boldText = String(remaining[..<boldEnd.lowerBound])
                    var boldAttrs = baseAttrs
                    boldAttrs[.font] = boldFont
                    result.append(NSAttributedString(string: boldText, attributes: boldAttrs))
                    remaining = String(remaining[boldEnd.upperBound...])
                } else {
                    result.append(NSAttributedString(string: "**", attributes: baseAttrs))
                }
            }
            else if let codeStart = remaining.range(of: "`") {
                let before = String(remaining[..<codeStart.lowerBound])
                if !before.isEmpty {
                    result.append(NSAttributedString(string: before, attributes: baseAttrs))
                }

                remaining = String(remaining[codeStart.upperBound...])

                if let codeEnd = remaining.range(of: "`") {
                    let codeText = String(remaining[..<codeEnd.lowerBound])
                    var codeAttrs = baseAttrs
                    codeAttrs[.font] = codeFont
                    codeAttrs[.backgroundColor] = NSColor(white: 0.15, alpha: 1)
                    result.append(NSAttributedString(string: " \(codeText) ", attributes: codeAttrs))
                    remaining = String(remaining[codeEnd.upperBound...])
                } else {
                    result.append(NSAttributedString(string: "`", attributes: baseAttrs))
                }
            }
            else {
                result.append(NSAttributedString(string: remaining, attributes: baseAttrs))
                remaining = ""
            }
        }

        return result
    }
}
