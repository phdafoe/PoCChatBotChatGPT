//
//  ViewModel.swift
//  PoCChatBotChatGPT
//
//  Created by TECDATA ENGINEERING on 26/4/23.
//

import Foundation
import SwiftUI

final class ViewModel: ObservableObject {
    @Published var isInteractingWithChatGPT = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    @Published var outputObfuscator: [UInt8] = []
    
    private let api: ChatGPTAPI
    
    init(api: ChatGPTAPI){
        self.api = api
    }
    
    @MainActor
    func sendTapped() async {
        let text = inputMessage
        inputMessage = ""
        await send(text: text)
        
    }
    
    @MainActor
    func retry(message: MessageRow) async {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        self.messages.remove(at: index)
        await send(text: message.sendText)
    }
    
    @MainActor
    private func send(text: String) async {
        isInteractingWithChatGPT = false
        var streamText = ""
        var messageRow = MessageRow(isInteractingWithChatGPT: true,
                                    sendImage: "profile",
                                    sendText: text,
                                    responseImage: "openai",
                                    responseText: streamText,
                                    responseError: nil)
        
        self.messages.append(messageRow)
        
        do {
            let stream = try await api.sendMesssageStream(text: text)
            for try await text in stream{
                streamText += text
                messageRow.responseText = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.messages[self.messages.count - 1] = messageRow
            }
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        messageRow.isInteractingWithChatGPT = false
        self.messages[self.messages.count - 1] = messageRow
        isInteractingWithChatGPT = false
    }
}


struct MessageRow: Identifiable {
    let id = UUID()
    var isInteractingWithChatGPT: Bool
    let sendImage: String
    let sendText: String
    let responseImage: String
    var responseText: String
    var responseError: String?
}
