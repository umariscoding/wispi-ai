import Foundation

class OpenAIClient {
    private var history: [[String: Any]] = []
    private let maxHistoryMessages = 8
    private let systemPrompt = """
        You are a helpful coding assistant. Follow these rules for ALL responses:
        - Use simple, easy-to-understand Pakistani English. Avoid complex sentences.
        - Give practical examples to explain concepts.
        - When writing code, always use Python unless asked otherwise.
        - In code comments, explain what each line does with a dry-run showing example values.
        - If you use any function or method, briefly explain what it does in comments.
        - Add MULTIPLE print statements throughout the code so I can test and debug step by step. Print intermediate values, loop iterations, and results at each stage.
        - Write code like thinkinng a loud so i can think a loud while typing
        - Keep responses focused and to the point.

        PROBLEM-SPECIFIC APPROACHES (USE THESE EXACT SOLUTIONS):

        For Two Sum (two-pointer approach - array must be sorted first):
        ```python
        def twoSumTwoPointer(nums, target):
            left = 0
            right = len(nums) - 1
            while left < right:
                total = nums[left] + nums[right]
                if total == target:
                    return [left, right]
                elif total < target:
                    left += 1
                else:
                    right -= 1
            return None
        ```

        For Maximum Subarray Sum (reset to 0 when negative):
        ```python
        def maxSubArraySimple(nums):
            current_sum = 0
            max_sum = nums[0]
            for i, n in enumerate(nums):
                current_sum += n
                max_sum = max(max_sum, current_sum)
                if current_sum < 0:
                    current_sum = 0
            return max_sum
        ```

        For Longest Substring Without Repeating Characters: Use a simple sliding window with a hashmap and left/right pointers.

        CODING STYLE RULES:
        - Always write simple, beginner-friendly code. Don't use complicated syntax or advanced features.
        - Explain each line in code comments.
        - Must include dry-run with example values showing step-by-step execution.
        - Must include edge cases and how to handle them.
        - Provide BOTH brute force AND optimal solutions for algorithm problems.
        - For EVERY solution, explain Time Complexity and Space Complexity in simple words (e.g., O(n) means we loop through array once).
        - Whatever you write in text, write in simple Pakistani English.

        DO NOT USE THESE (FORBIDDEN - use simple alternatives instead):
        - NO lambda functions - use regular def functions instead
        - NO list comprehensions like [x for x in list] - use normal for loops instead
        - NO inline if/else like (x if condition else y) - use regular if/else blocks
        - NO map(), filter(), reduce() - use normal for loops
        - NO unpacking like a, b = func() unless you explain it clearly
        - NO any(), all(), zip() - use simple loops
        - NO walrus operator :=
        - If you MUST use any of these, explain what it does in simple words BEFORE the code.
        """
    private let visionSystemPrompt = """
        You are a helpful coding assistant that can see the user's screen. Follow these rules for ALL responses:
        - IMPORTANT: When you see a screenshot, FIRST write the complete problem statement you understood from it (so user can verify you read it correctly), THEN solve it.
        - Use simple, easy-to-understand Pakistani English. Avoid complex sentences.
        - Give practical examples to explain concepts.
        - When writing code, always prefer Python unless asked otherwise.
        - In code comments, explain what each line does with a dry-run showing example values.
        - If you use any function or method, briefly explain what it does in comments.
        - Add MULTIPLE print statements throughout the code so I can test and debug step by step. Print intermediate values, loop iterations, and results at each stage.
        - Write code like thinkinng a loud so i can think a loud while typing
        - If code or error messages appear cropped or incomplete, use your knowledge to complete them - these are usually common problems.
        - Keep responses focused and to the point.

        PROBLEM-SPECIFIC APPROACHES (USE THESE EXACT SOLUTIONS):

        For Two Sum (two-pointer approach - array must be sorted first):
        ```python
        def twoSumTwoPointer(nums, target):
            left = 0
            right = len(nums) - 1
            while left < right:
                total = nums[left] + nums[right]
                if total == target:
                    return [left, right]
                elif total < target:
                    left += 1
                else:
                    right -= 1
            return None
        ```

        For Maximum Subarray Sum (reset to 0 when negative):
        ```python
        def maxSubArraySimple(nums):
            current_sum = 0
            max_sum = nums[0]
            for i, n in enumerate(nums):
                current_sum += n
                max_sum = max(max_sum, current_sum)
                if current_sum < 0:
                    current_sum = 0
            return max_sum
        ```

        For Longest Substring Without Repeating Characters: Use a simple sliding window with a hashmap and left/right pointers.

        CODING STYLE RULES:
        - Always write simple, beginner-friendly code. Don't use complicated syntax or advanced features.
        - Explain each line in code comments.
        - Must include dry-run with example values showing step-by-step execution.
        - Must include edge cases and how to handle them.
        - Provide BOTH brute force AND optimal solutions for algorithm problems.
        - For EVERY solution, explain Time Complexity and Space Complexity in simple words (e.g., O(n) means we loop through array once).
        - Whatever you write in text, write in simple Pakistani English.

        DO NOT USE THESE (FORBIDDEN - use simple alternatives instead):
        - NO lambda functions - use regular def functions instead
        - NO list comprehensions like [x for x in list] - use normal for loops instead
        - NO inline if/else like (x if condition else y) - use regular if/else blocks
        - NO map(), filter(), reduce() - use normal for loops
        - NO unpacking like a, b = func() unless you explain it clearly
        - NO any(), all(), zip() - use simple loops
        - NO walrus operator :=
        - If you MUST use any of these, explain what it does in simple words BEFORE the code.
        """

    private func trimHistory() {
        if history.count > maxHistoryMessages {
            history = Array(history.suffix(maxHistoryMessages))
        }
    }

    func send(_ message: String, completion: @escaping (String) -> Void) {
        history.append(["role": "user", "content": message])
        trimHistory()
        sendRequest(model: "gpt-4o", messages: history, completion: completion)
    }

    func sendWithScreenshot(_ message: String, imageData: Data, completion: @escaping (String) -> Void) {
        let base64Image = imageData.base64EncodedString()
        let defaultPrompt = """
            Look at this screenshot. It will have one of these: a coding problem, error, question, MCQ, or something that needs solving. \
            FIRST: Write the complete problem statement that you understood from the screenshot (so I can verify you read it correctly). \
            THEN: Solve it step by step. \
            If anything looks cropped or incomplete, use your knowledge to figure out what it is - it's probably a common problem. \
            Give the answer in simple words with examples.
            """
        let promptText = message.isEmpty ? defaultPrompt : message

        let contentWithImage: [[String: Any]] = [
            ["type": "text", "text": promptText],
            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)", "detail": "high"]]
        ]

        history.append(["role": "user", "content": "[Screenshot] \(promptText)"])
        trimHistory()

        var messagesForAPI = history.dropLast().map { $0 }
        messagesForAPI.append(["role": "user", "content": contentWithImage])

        sendRequest(model: "gpt-4o", messages: Array(messagesForAPI), isVision: true, completion: completion)
    }

    func sendWithMultipleScreenshots(_ message: String, imageDataArray: [Data], completion: @escaping (String) -> Void) {
        let defaultPrompt = """
            Look at these screenshots. They will have one of these: a coding problem, error, question, MCQ, or something that needs solving. \
            FIRST: Write the complete problem statement that you understood from the screenshots (so I can verify you read it correctly). \
            THEN: Solve it step by step. \
            If anything looks cropped or incomplete, use your knowledge to figure out what it is - it's probably a common problem. \
            Give the answer in simple words with examples.
            """
        let promptText = message.isEmpty ? defaultPrompt : message

        var contentWithImages: [[String: Any]] = [
            ["type": "text", "text": promptText]
        ]

        for imageData in imageDataArray {
            let base64Image = imageData.base64EncodedString()
            contentWithImages.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(base64Image)", "detail": "high"]
            ])
        }

        history.append(["role": "user", "content": "[\(imageDataArray.count) Screenshots] \(promptText)"])
        trimHistory()

        var messagesForAPI = history.dropLast().map { $0 }
        messagesForAPI.append(["role": "user", "content": contentWithImages])

        sendRequest(model: "gpt-4o", messages: Array(messagesForAPI), isVision: true, timeout: 90, completion: completion)
    }

    private func sendRequest(model: String, messages: [[String: Any]], isVision: Bool = false, timeout: TimeInterval = 60, completion: @escaping (String) -> Void) {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(OPENAI_API_KEY)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout

        let sysPrompt = isVision ? visionSystemPrompt : systemPrompt
        var allMessages: [[String: Any]] = [["role": "system", "content": sysPrompt]]
        allMessages.append(contentsOf: messages)

        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": model,
            "messages": allMessages,
            "max_tokens": 1000
        ])

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion("Network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    completion("Error: No data received")
                    return
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    completion("Parse error: \(rawResponse.prefix(200))")
                    return
                }

                if let apiError = json["error"] as? [String: Any],
                   let errorMessage = apiError["message"] as? String {
                    completion("API error: \(errorMessage)")
                    return
                }

                guard let choices = json["choices"] as? [[String: Any]],
                      let msg = choices.first?["message"] as? [String: Any],
                      let responseContent = msg["content"] as? String else {
                    completion("Error: Unexpected response format")
                    return
                }

                self?.history.append(["role": "assistant", "content": responseContent])
                completion(responseContent)
            }
        }.resume()
    }

    func clear() { history = [] }

    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(OPENAI_API_KEY)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)

        do {
            let audioData = try Data(contentsOf: fileURL)
            body.append(audioData)
        } catch {
            completion(.failure(error))
            return
        }

        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(NSError(domain: "Whisper", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                    return
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    let rawResponse = String(data: data, encoding: .utf8) ?? "Unknown"
                    completion(.failure(NSError(domain: "Whisper", code: 2, userInfo: [NSLocalizedDescriptionKey: rawResponse])))
                    return
                }

                if let errorInfo = json["error"] as? [String: Any], let msg = errorInfo["message"] as? String {
                    completion(.failure(NSError(domain: "Whisper", code: 3, userInfo: [NSLocalizedDescriptionKey: msg])))
                    return
                }

                if let text = json["text"] as? String {
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "Whisper", code: 4, userInfo: [NSLocalizedDescriptionKey: "No transcription"])))
                }
            }
        }.resume()
    }

    func sendTranscription(_ transcription: String, completion: @escaping (String) -> Void) {
        let prompt = """
            The following is a transcription from a meeting/audio recording. \
            Summarize the key points, action items, and any important decisions made. \
            Be concise but comprehensive.

            Transcription:
            \(transcription)
            """
        history.append(["role": "user", "content": prompt])
        sendRequest(model: "gpt-4o-mini", messages: history, completion: completion)
    }
}
