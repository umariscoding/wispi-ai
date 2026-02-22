import Cocoa

class MessageView: FlippedView {
    init(text: String, isUser: Bool, width: CGFloat) {
        super.init(frame: .zero)

        var views: [NSView] = []
        let parts = parseContent(text)

        for part in parts {
            if part.isCode {
                views.append(CodeBlockView(code: part.content, language: part.language, width: width))
            } else {
                let trimmed = part.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    views.append(TextBubbleView(text: trimmed, isUser: isUser, width: width))
                }
            }
        }

        var y: CGFloat = 0
        for v in views {
            v.frame.origin.y = y
            addSubview(v)
            y += v.frame.height + 6
        }

        frame = NSRect(x: 0, y: 0, width: width, height: max(y - 6, 0))
    }
    required init?(coder: NSCoder) { fatalError() }

    struct Part { let content: String; let isCode: Bool; let language: String }

    func parseContent(_ text: String) -> [Part] {
        var parts: [Part] = []
        var remaining = text

        while let start = remaining.range(of: "```") {
            let before = String(remaining[..<start.lowerBound])
            if !before.isEmpty { parts.append(Part(content: before, isCode: false, language: "")) }
            remaining = String(remaining[start.upperBound...])

            if let end = remaining.range(of: "```") {
                var code = String(remaining[..<end.lowerBound])
                var lang = ""
                if let nl = code.firstIndex(of: "\n") {
                    let first = String(code[..<nl]).trimmingCharacters(in: .whitespaces)
                    if !first.contains(" ") && first.count < 15 { lang = first; code = String(code[code.index(after: nl)...]) }
                }
                parts.append(Part(content: code, isCode: true, language: lang))
                remaining = String(remaining[end.upperBound...])
            } else {
                parts.append(Part(content: remaining, isCode: true, language: ""))
                remaining = ""
            }
        }
        if !remaining.isEmpty { parts.append(Part(content: remaining, isCode: false, language: "")) }
        return parts
    }
}
