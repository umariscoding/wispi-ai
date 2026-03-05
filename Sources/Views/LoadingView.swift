import Cocoa

class LoadingView: FlippedView {
    private let dot1 = NSView()
    private let dot2 = NSView()
    private let dot3 = NSView()

    init() {
        super.init(frame: NSRect(x: 10, y: 0, width: 50, height: 32))
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.backgroundColor = Theme.aiBubble.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(white: 0.25, alpha: 0.3).cgColor
        layer?.masksToBounds = true

        setupDots()
        animateDots()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupDots() {
        let dotSize: CGFloat = 5
        let spacing: CGFloat = 4
        let startX: CGFloat = 12

        for (idx, dot) in [dot1, dot2, dot3].enumerated() {
            dot.frame = NSRect(x: startX + CGFloat(idx) * (dotSize + spacing), y: 13, width: dotSize, height: dotSize)
            dot.wantsLayer = true
            dot.layer?.cornerRadius = dotSize / 2
            dot.layer?.backgroundColor = Theme.textMuted.cgColor
            addSubview(dot)
        }
    }

    private func animateDots() {
        for (idx, dot) in [dot1, dot2, dot3].enumerated() {
            let delay = Double(idx) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.animateDot(dot)
            }
        }
    }

    private func animateDot(_ dot: NSView) {
        guard let layer = dot.layer else { return }

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.4
        animation.toValue = 1.0
        animation.duration = 0.6
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        layer.add(animation, forKey: "bounce")
    }
}
