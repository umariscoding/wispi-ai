import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreMedia

class AudioRecorder: NSObject, SCStreamDelegate, SCStreamOutput {
    private var stream: SCStream?
    private var audioFileURL: URL?
    private var audioWriter: AVAssetWriter?
    private var audioInput: AVAssetWriterInput?
    private var isRecording = false
    private var onComplete: ((Result<URL, Error>) -> Void)?
    private var hasStartedWriting = false

    var recording: Bool { isRecording }

    func startRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        guard !isRecording else {
            completion(.failure(NSError(domain: "AudioRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Already recording"])))
            return
        }

        onComplete = completion
        hasStartedWriting = false

        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { [weak self] content, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let content = content, let display = content.displays.first else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "AudioRecorder", code: 2, userInfo: [NSLocalizedDescriptionKey: "No display found"])))
                }
                return
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])

            let config = SCStreamConfiguration()
            config.width = 2
            config.height = 2
            config.minimumFrameInterval = CMTime(value: 1, timescale: 1)
            config.capturesAudio = true
            config.sampleRate = 44100
            config.channelCount = 1

            do {
                let stream = SCStream(filter: filter, configuration: config, delegate: self)
                try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: DispatchQueue(label: "audio.capture"))

                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "recording_\(Int(Date().timeIntervalSince1970)).m4a"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try? FileManager.default.removeItem(at: fileURL)

                self.audioFileURL = fileURL

                let writer = try AVAssetWriter(outputURL: fileURL, fileType: .m4a)

                let audioSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderBitRateKey: 128000
                ]

                let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                input.expectsMediaDataInRealTime = true
                writer.add(input)

                self.audioWriter = writer
                self.audioInput = input

                stream.startCapture { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self.isRecording = true
                            self.stream = stream
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func stopRecording() {
        guard isRecording, let stream = stream else { return }

        isRecording = false

        stream.stopCapture { [weak self] error in
            guard let self = self else { return }

            self.audioInput?.markAsFinished()
            self.audioWriter?.finishWriting {
                DispatchQueue.main.async {
                    self.stream = nil
                    self.audioWriter = nil
                    self.audioInput = nil

                    if let error = error {
                        self.onComplete?(.failure(error))
                    } else if let url = self.audioFileURL {
                        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                           let size = attrs[.size] as? Int, size > 1000 {
                            self.onComplete?(.success(url))
                        } else {
                            self.onComplete?(.failure(NSError(domain: "AudioRecorder", code: 3,
                                userInfo: [NSLocalizedDescriptionKey: "Recording too short or empty. Try recording for at least 2 seconds."])))
                        }
                    }
                    self.onComplete = nil
                }
            }
        }
    }

    // SCStreamOutput
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, isRecording else { return }
        guard let writer = audioWriter, let input = audioInput else { return }
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }

        if !hasStartedWriting {
            let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            writer.startWriting()
            writer.startSession(atSourceTime: startTime)
            hasStartedWriting = true
        }

        if input.isReadyForMoreMediaData {
            input.append(sampleBuffer)
        }
    }

    // SCStreamDelegate
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.stream = nil
        }
    }
}
