import Cocoa

class ScreenshotBubbleView: FlippedView {
    init(screenshots: [Data], prompt: String = "", isUser: Bool, width: CGFloat) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.masksToBounds = true
        layer?.backgroundColor = isUser ? Theme.userBubble.cgColor : Theme.aiBubble.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = isUser ? NSColor(white: 0.40, alpha: 0.2).cgColor : NSColor(white: 0.25, alpha: 0.25).cgColor

        let maxContentWidth = (width / 2) - 40
        var currentY: CGFloat = 8
        let spacing: CGFloat = 8
        var maxImageWidth: CGFloat = 0

        // Display images vertically stacked with proper sizing
        let imagesToShow = min(3, screenshots.count)
        for (idx, screenshotData) in screenshots.enumerated() {
            guard idx < imagesToShow else { break }

            if let image = NSImage(data: screenshotData) {
                // Calculate dimensions preserving aspect ratio
                let aspectRatio = image.size.width / image.size.height
                let imageWidth = min(maxContentWidth, 200.0)
                let imageHeight = imageWidth / aspectRatio

                let imageView = NSImageView(frame: NSRect(x: 8, y: currentY, width: imageWidth, height: imageHeight))
                imageView.image = image
                imageView.imageScaling = .scaleProportionallyUpOrDown
                imageView.wantsLayer = true
                imageView.layer?.cornerRadius = 8
                imageView.layer?.masksToBounds = true
                addSubview(imageView)

                maxImageWidth = max(maxImageWidth, imageWidth)
                currentY += imageHeight + spacing
            }
        }

        // Show "+N more" if there are additional screenshots
        if screenshots.count > imagesToShow {
            let moreLabel = NSTextField(labelWithString: "+\(screenshots.count - imagesToShow) more")
            moreLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            moreLabel.textColor = Theme.textMuted
            moreLabel.frame = NSRect(x: 8, y: currentY, width: 150, height: 20)
            addSubview(moreLabel)
            currentY += 24
        }

        // Add prompt/caption if present
        if !prompt.isEmpty {
            let promptLabel = NSTextField(wrappingLabelWithString: prompt)
            promptLabel.font = NSFont.systemFont(ofSize: 12)
            promptLabel.textColor = Theme.textPrimary
            promptLabel.frame = NSRect(x: 8, y: currentY, width: maxContentWidth, height: 1000)
            promptLabel.sizeToFit()
            addSubview(promptLabel)
            currentY += promptLabel.frame.height + 4
        }

        let bubbleWidth = max(maxImageWidth + 16, 120)
        let bubbleHeight = currentY + 8

        if isUser {
            frame = NSRect(x: width - bubbleWidth - 10, y: 0, width: bubbleWidth, height: bubbleHeight)
        } else {
            frame = NSRect(x: 10, y: 0, width: bubbleWidth, height: bubbleHeight)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}
