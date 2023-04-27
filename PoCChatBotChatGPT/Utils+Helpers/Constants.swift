//
//  Constants.swift
//  PoCChatBotChatGPT
//
//  Created by TECDATA ENGINEERING on 27/4/23.
//

import Foundation

struct Constants {
    
    struct OpenAI {
        static let openAIKey = "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"
        static let url = "https://api.openai.com/v1/completions"
        static let basePrompt = "You are ChatGPT, a large languaje model trained by OpenAI. Ypu answer as consisely as possible for each response (e.g Don't be verbose). It is very important for you to answer as consisely as possible, so pleease remember this. If you are generating a list, do not have too many items.\n\n\n"
        static let model = "text-davinci-003"
        static let temperature = 0.5
        static let maxTokens = 1024
        static let invalidResponse = "Invalid response"
        static let badResponse = "Bad response: "
    }
}

// Data model
struct CompletionResponse: Decodable {
    let choices: [Choices]
}
struct Choices: Decodable {
    var text: String
}

// Extensions
extension String: Error{}
