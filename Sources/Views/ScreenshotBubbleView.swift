import Cocoa

class ScreenshotBubbleView: FlippedView {
    init(screenshots: [Data], prompt: String = "", isUser: Bool, width: CGFloat) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.masksToBounds = true

        // Screenshots are wide (screen captures), use most of available width
        let imageDisplayWidth = min(width - 40, 340.0)
        var currentY: CGFloat = 4
        let spacing: CGFloat = 4

        // Stack screenshots vertically
        let imagesToShow = min(3, screenshots.count)
        for (idx, screenshotData) in screenshots.enumerated() {
            guard idx < imagesToShow else { break }

            if let image = NSImage(data: screenshotData) {
                let aspectRatio = image.size.width / image.size.height
                let imageHeight = imageDisplayWidth / aspectRatio

                let imageView = NSImageView(frame: NSRect(x: 4, y: currentY, width: imageDisplayWidth, height: imageHeight))
                imageView.image = image
                imageView.imageScaling = .scaleProportionallyUpOrDown
                imageView.wantsLayer = true
                imageView.layer?.cornerRadius = 8
                imageView.layer?.masksToBounds = true
                addSubview(imageView)

                currentY += imageHeight + spacing
            }
        }

        // "+N more" label
        if screenshots.count > imagesToShow {
            let moreLabel = NSTextField(labelWithString: "+\(screenshots.count - imagesToShow) more")
            moreLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
            moreLabel.textColor = Theme.textMuted
            moreLabel.frame = NSRect(x: 8, y: currentY, width: 100, height: 16)
            addSubview(moreLabel)
            currentY += 20
        }

        // Caption below images
        if !prompt.isEmpty {
            let promptLabel = NSTextField(wrappingLabelWithString: prompt)
            promptLabel.font = NSFont.systemFont(ofSize: 12)
            promptLabel.textColor = Theme.textPrimary
            promptLabel.frame = NSRect(x: 8, y: currentY + 2, width: imageDisplayWidth - 8, height: 1000)
            promptLabel.sizeToFit()
            addSubview(promptLabel)
            currentY += promptLabel.frame.height + 6
        }

        let bubbleWidth = imageDisplayWidth + 8
        let bubbleHeight = currentY + 4

        if isUser {
            frame = NSRect(x: width - bubbleWidth - 10, y: 0, width: bubbleWidth, height: bubbleHeight)
        } else {
            frame = NSRect(x: 10, y: 0, width: bubbleWidth, height: bubbleHeight)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}
