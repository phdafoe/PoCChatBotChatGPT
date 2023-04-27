//
//  API.swift
//  PoCChatBotChatGPT
//
//  Created by TECDATA ENGINEERING on 24/4/23.
//


import Foundation

class ChatGPTAPI {
    
    private let apiKey: String
    private var historyList = [String]()
    private let urlSession = URLSession.shared
    private var urlRequest: URLRequest{
        let url = URL(string: Constants.OpenAI.url)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        return urlRequest
    }
    
    private let jsonDecoder = JSONDecoder()
    private var basePrompt = Constants.OpenAI.basePrompt
    
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
    
    /// generateChatGPTPrompt
    /// - Parameter text: from text: String
    /// - Returns: -> String
    private func generateChatGPTPrompt(from text: String) -> String {
        var prompt = basePrompt + historyListText + "User: \(text)\n\n\nChatGPT:"
        if prompt.count > (4000 * 4){
            _ = historyList.dropFirst()
            prompt = generateChatGPTPrompt(from: text)
        }
        return prompt
    }
    
    
    /// jsonBody
    /// - Parameters:
    ///   - text: text: String
    ///   - stream: stream: Bool = true
    /// - Returns:  throws -> Data
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let jsonBody: [String: Any] = [
            "model" : Constants.OpenAI.model,
            "temperature": Constants.OpenAI.temperature,
            "max_tokens":Constants.OpenAI.maxTokens,
            "prompt": generateChatGPTPrompt(from: text),
            "stop": ["\n\n\n", "<|im_end|>"],
            "stream": stream
        ]
        return try JSONSerialization.data(withJSONObject: jsonBody)
    }
    
    /// sendMesssageStream
    /// - Parameter text: text: String
    /// - Returns: async throws -> AsyncThrowingStream<String, Error>
    func sendMesssageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text)
        
        let (result, response) = try await urlSession.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Constants.OpenAI.invalidResponse
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw "\(Constants.OpenAI.badResponse) \(httpResponse.statusCode)"
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
    
    
    /// senMessage
    /// - Parameter text: text: String
    /// - Returns: async throws -> String
    func senMessage(text: String) async throws -> String {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text, stream: false)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Constants.OpenAI.invalidResponse
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw "\(Constants.OpenAI.badResponse) \(httpResponse.statusCode)"
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




