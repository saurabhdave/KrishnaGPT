//
//  ChatGPTViewModel.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation

final class ChatGPTViewModel: ObservableObject {
    
    @Published var isInteractingWithChatGPT = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    @Published var selectedLanguage = LanguageType.english
    
    private let chatService: ChatNetworking
    
    init(service: ChatNetworking) {
        self.chatService = service
    }
    
    @MainActor
    private func send(text: String) async {
        isInteractingWithChatGPT = true
        var streamText = ""
        var msgRow = MessageRow(isInteractingWithChatGPT: true,
                                sendImage: "profile",
                                sendText: text,
                                responseImage: "krishnaai",
                                responseText: streamText,
                                responseError: nil)
        
        messages.append(msgRow)
        let messageIndex = messages.count - 1
        
        do {
            let stream = try await chatService.sendMessageStream(text: text, language: selectedLanguage)
            for try await text in stream {
                streamText += text
                msgRow.responseText = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard messages.indices.contains(messageIndex) else { break }
                messages[messageIndex] = msgRow
            }
        } catch {
            msgRow.responseError = error.localizedDescription
        }
        
        msgRow.isInteractingWithChatGPT = false
        guard messages.indices.contains(messageIndex) else {
            isInteractingWithChatGPT = false
            return
        }
        messages[messageIndex] = msgRow
        isInteractingWithChatGPT = false
    }
    
    @MainActor
    func sendTapped() async {
        let text = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputMessage = ""
        await send(text: text)
    }
    
    @MainActor
    func clearMessages() async {
        await chatService.clearHistory()
        messages.removeAll()
    }
    
    @MainActor
    func retry(message: MessageRow) async {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        
        self.messages.remove(at: index)
        await send(text: message.sendText)
    }
}
