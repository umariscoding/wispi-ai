import Cocoa

class RecordingBannerView: FlippedView {
    private let statusDot = NSView()
    private let label = NSTextField(labelWithString: "Recording...")
    private var recordingTimer: Timer?
    private var secondsElapsed: Int = 0

    init(width: CGFloat) {
        super.init(frame: NSRect(x: 0, y: 36, width: width, height: 32))
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 0.20, green: 0.08, blue: 0.08, alpha: 0.40).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(red: 0.50, green: 0.20, blue: 0.20, alpha: 0.3).cgColor

        // Red pulsing dot
        statusDot.frame = NSRect(x: 10, y: 10, width: 8, height: 8)
        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 4
        statusDot.layer?.backgroundColor = Theme.statusRecording.cgColor
        addSubview(statusDot)

        // Text label with timer
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = Theme.textPrimary
        label.frame = NSRect(x: 26, y: 8, width: 200, height: 16)
        label.stringValue = "Recording... 0:00"
        addSubview(label)

        // Pulse animation
        animateDot()

        // Start timer
        startTimer()
    }

    required init?(coder: NSCoder) { fatalError() }

    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        label.stringValue = "Processing..."
        secondsElapsed = 0
    }

    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsElapsed += 1
            let minutes = self.secondsElapsed / 60
            let seconds = self.secondsElapsed % 60
            DispatchQueue.main.async {
                self.label.stringValue = String(format: "Recording... %d:%02d", minutes, seconds)
            }
        }
    }

    private func animateDot() {
        guard let layer = statusDot.layer else { return }

        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1.0
        pulse.toValue = 0.4
        pulse.duration = 0.8
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        layer.add(pulse, forKey: "pulse")
    }
}
