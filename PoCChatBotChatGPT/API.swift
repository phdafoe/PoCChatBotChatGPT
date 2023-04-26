//
//  API.swift
//  PoCChatBotChatGPT
//
//  Created by TECDATA ENGINEERING on 24/4/23.
//

//struct Key {
//
//}

import Foundation

class ChatGPTAPI {
    static let openAIKey = "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"
    private let apiKey: String
    private var historyList = [String]()
    private let urlSession = URLSession.shared
    private var urlRequest: URLRequest{
        let url = URL(string: "https://api.openai.com/v1/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        return urlRequest
    }
    
    private let jsonDecoder = JSONDecoder()
    private var basePrompt = "You are ChatGPT, a large languaje model trained by OpenAI. Ypu answer as consisely as possible for each response (e.g Don't be verbose). It is very important for you to answer as consisely as possible, so pleease remember this. If you are generating a list, do not have too many items.\n\n\n"
    
    private var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
    }
    
    private var historyListText: String {
        historyList.joined()
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    private func generateChatGPTPrompt(from text: String) -> String {
        var prompt = basePrompt + historyListText + "User: \(text)\n\n\nChatGPT:"
        if prompt.count > (4000 * 4){
            _ = historyList.dropFirst()
            prompt = generateChatGPTPrompt(from: text)
        }
        return prompt
    }
    
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let jsonBody: [String: Any] = [
            "model" : "text-davinci-003",
            "temperature": 0.5,
            "max_tokens":1024,
            "prompt": generateChatGPTPrompt(from: text),
            "stop": ["\n\n\n", "<|im_end|>"],
            "stream": stream
        ]
        return try JSONSerialization.data(withJSONObject: jsonBody)
    }
    
    func sendMesssageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text)
        
        let (result, response) = try await urlSession.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw "Bad response: \(httpResponse.statusCode)"
        }
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do{
                    var streamText = ""
                    for try await line in result.lines{
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? self.jsonDecoder.decode(CompletionResponse.self, from: data),
                           let text = response.choices.first?.text{
                            streamText += text
                            continuation.yield(text)
                        }
                    }
                    self.historyList.append(streamText)
                    continuation.finish()
                }catch{
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func senMessage(text: String) async throws -> String {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text, stream: false)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw "Bad response: \(httpResponse.statusCode)"
        }
        
        do {
            let completionResponse = try self.jsonDecoder.decode(CompletionResponse.self, from: data)
            let responseText = completionResponse.choices.first?.text ?? ""
            self.historyList.append(responseText)
            return responseText
        }catch{
            throw error
        }
    }
    
    
}

extension String: Error{
    
}

struct CompletionResponse: Decodable {
    let choices: [Choices]
}
struct Choices: Decodable {
    var text: String
}
