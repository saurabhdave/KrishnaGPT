//
//  ChatGPTViewModel.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation

@MainActor
final class ChatGPTViewModel: ObservableObject {
    
    @Published var isInteractingWithChatGPT = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    @Published var selectedLanguage = LanguageType.english
    
    var isSendDisabled: Bool {
        inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    let suggestedQuestions = [
        "What is the meaning of dharma?",
        "How do I overcome fear and anxiety?",
        "What does the Gita say about karma?",
        "How to find inner peace?"
    ]
    
    private let chatService: ChatNetworking
    
    init(service: ChatNetworking) {
        self.chatService = service
    }
    
    private func send(text: String) async {
        isInteractingWithChatGPT = true
        var streamText = ""
        var msgRow = MessageRow(isInteractingWithChatGPT: true,
                                sendImage: MessageRow.userImage,
                                sendText: text,
                                responseImage: MessageRow.assistantImage,
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
    
    func sendTapped() async {
        let text = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputMessage = ""
        await send(text: text)
    }
    
    func clearMessages() async {
        await chatService.clearHistory()
        messages.removeAll()
    }
    
    func retry(message: MessageRow) async {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        
        self.messages.remove(at: index)
        await send(text: message.sendText)
    }
}
