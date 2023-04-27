//
//  Constants.swift
//  PoCChatBotChatGPT
//
//  Created by TECDATA ENGINEERING on 27/4/23.
//

import Foundation

struct Constants {
    
    struct OpenAI {
        static let openAIKey: [UInt8] = [55, 30, 64, 92, 17, 120, 13, 39, 15, 42, 32, 4, 19, 32, 2, 7, 17, 30, 17, 89, 56, 47, 18, 59, 88, 39, 34, 49, 36, 36, 32, 48, 41, 68, 41, 71, 5, 29, 35, 18, 55, 18, 40, 7, 55, 26, 53, 34, 61, 45, 37] //"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"
        static let url: [UInt8] = [44, 1, 25, 29, 10, 112, 64, 68, 4, 62, 58, 97, 13, 26, 0, 13, 21, 45, 91, 14, 2, 20, 101, 25, 90, 74, 45, 60, 34, 18, 6, 0, 23, 29, 43, 27, 30] //"https://api.openai.com/v1/completions"
        static let basePrompt = "You are ChatGPT, a large languaje model trained by OpenAI. Ypu answer as consisely as possible for each response (e.g Don't be verbose). It is very important for you to answer as consisely as possible, so pleease remember this. If you are generating a list, do not have too many items.\n\n\n"
        static let model: [UInt8] = [48, 16, 21, 25, 84, 46, 14, 29, 12, 32, 48, 38, 79, 90, 85, 80]//"text-davinci-003"
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
