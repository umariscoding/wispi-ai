import Cocoa
import ScreenCaptureKit

enum CaptureError: Error {
    case noPermission(String)
    case noDisplay
    case captureFailed(String)
}

class ScreenCapture {
    static func captureScreen(completion: @escaping (Result<Data, CaptureError>) -> Void) {
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { content, error in
            if let error = error {
                let nsError = error as NSError
                DispatchQueue.main.async {
                    completion(.failure(.noPermission("[\(nsError.domain):\(nsError.code)] \(error.localizedDescription)")))
                }
                return
            }

            guard let content = content else {
                DispatchQueue.main.async { completion(.failure(.noPermission("Content is nil"))) }
                return
            }

            guard let display = content.displays.first else {
                DispatchQueue.main.async { completion(.failure(.noDisplay)) }
                return
            }

            let currentPID = ProcessInfo.processInfo.processIdentifier
            let excludedApps = content.applications.filter { $0.processID == currentPID }

            let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])

            let config = SCStreamConfiguration()
            config.width = Int(display.width * 2)
            config.height = Int(display.height * 2)
            config.scalesToFit = true
            config.showsCursor = false

            SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, error in
                DispatchQueue.main.async {
                    if let error = error {
                        let nsError = error as NSError
                        completion(.failure(.captureFailed("[\(nsError.domain):\(nsError.code)] \(error.localizedDescription)")))
                        return
                    }

                    guard let image = image else {
                        completion(.failure(.captureFailed("No image returned")))
                        return
                    }

                    let bitmapRep = NSBitmapImageRep(cgImage: image)
                    if let data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.4]) {
                        completion(.success(data))
                    } else {
                        completion(.failure(.captureFailed("Failed to encode image")))
                    }
                }
            }
        }
    }

    static func requestPermission() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
