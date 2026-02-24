//
//  ChatGPTAPI.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation

final class ChatGPTAPI {
    
    private let systemMessage: Message
    private let temperature: Double
    private let model: String
    
    private var apiKey: String
    private let urlSession = URLSession.shared
    private var urlRequest: URLRequest {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        return urlRequest
    }
    
    private var headers: [String: String] {
        [
            "Content-Type" : "application/json",
            "Authorization" : "Bearer \(apiKey)"
            
        ]
    }
    
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()
    private var selectedLanguage: LanguageType = .english
    private var selectedLanguageString: String {
        return "\nAnswer in \(selectedLanguage) and do not answer as the user."
    }
    
    private var historyList = [Message]()
    
    init(apiKey: String, model: String = "gpt-3.5-turbo", systemPrompt: String = "You are Krishna, answer according to the 18 chapters and 700 verses of the Bhagavad Gita, which contains life lessons on morality, strength, discipline and spirituality with relevent emoji. Professionally respond conversationally from Bhagavad Geeta and the chapter and verse labeled '1'. and '2.'.", temperature: Double = 0.5) {
        self.apiKey = apiKey
        self.model = model
        self.systemMessage = .init(role: "system", content: systemPrompt)
        self.temperature = temperature
    }
    
    private func generateChatGPTMessage(from text: String) -> [Message] {
        var messages = [systemMessage] + historyList + [Message(role: "user", content: text + selectedLanguageString)]
        
        if messages.contentCount > (4000 * 4) { // equivalent of 4 tokens per character, approximate
            _ = historyList.dropFirst()
            messages = generateChatGPTMessage(from: text)
        }
        return messages
    }
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let request = Request(model: model, temperature: temperature, messages: generateChatGPTMessage(from: text), stream: stream)
        return try JSONEncoder().encode(request)
    }
}

extension ChatGPTAPI {
    
    private func appendToHistoryList(userText: String, responseText: String) {
        self.historyList.append(.init(role: "user", content: userText))
        self.historyList.append(.init(role: "assistant", content: responseText))
        if historyList.count > 100 {
            historyList.removeFirst(2) // Remove oldest user-assistant pair
        }
    }
    
    func setChatGPTLanguage(languageType: LanguageType) {
        self.selectedLanguage = languageType
    }
    
    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        
        var urlReq = self.urlRequest
        urlReq.httpBody = try jsonBody(text: text)
        
        let (result, response) =  try await urlSession.bytes(for: urlReq)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var errorText = ""
            
            for try await line in result.lines {
                errorText.append(line)
            }
            
            if let data = errorText.data(using: .utf8), let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
                errorText = "\n\(errorResponse.message)"
            }
            
            throw "Bad Response: \(httpResponse.statusCode), \(errorText)"
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) { [weak self] in
                guard let self else { return}
                do {
                    var streamText = ""
                    for try await line in result.lines {
                        if line.hasPrefix("data: "), let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? self.jsonDecoder.decode(StreamCompletionResponse.self, from: data), let text = response.choices.first?.delta.content {
                            streamText += text
                            continuation.yield(text)
                        }
                    }
                    self.appendToHistoryList(userText: text, responseText: streamText)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        
    }
    
    func sendMessage(_ text: String) async throws -> String {
        
        var urlReq = self.urlRequest
        urlReq.httpBody = try jsonBody(text: text, stream: false)
        
        let (data, response) =  try await urlSession.data(for: urlReq)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var error = "Bad Response: \(httpResponse.statusCode)"
            if let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
                error.append("\n\(errorResponse.message)")
            }
            throw error
        }
        
        do {
            let completionResponse = try self.jsonDecoder.decode(CompletionResponse.self, from: data)
            let responseText = completionResponse.choices.first?.message.content ?? ""
            self.appendToHistoryList(userText: text, responseText: responseText)
            return responseText
        } catch {
            throw error
        }
        
    }
    
    func deleteHistoryList() {
        self.historyList.removeAll()
    }
}

extension String: CustomNSError {
    
    public var errorUserInfo: [String : Any] {
        [
            NSLocalizedDescriptionKey: self
        ]
     }
 }
