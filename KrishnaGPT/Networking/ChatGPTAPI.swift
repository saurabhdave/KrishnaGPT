//
//  ChatGPTAPI.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation

final class ChatGPTAPI {
    
    private var apiKey: String
    private let urlSession = URLSession.shared
    private var urlRequest: URLRequest {
        let url = URL(string: "https://api.openai.com/v1/completions")!
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
    
    private let jsonDecoder = JSONDecoder()
    private var selectedLanguage: LanguageType = .english
    private var selectedLanguageString: String {
        return "\nAnswer in \(selectedLanguage) and do not answer as the user."
    }

    private var basePrompt: String {
        "You are Krishna, answer according to the 18 chapters and 700 verses of the Bhagavad Gita, which contains life lessons on morality, strength, discipline and spirituality with relevent emoji. Professionally respond conversationally from Bhagavad Geeta and the chapter and verse labeled '1'. and '2.'.\n\n"
    }
    
    private var historyList = [String]()
    private var historyListText: String {
        historyList.joined()
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    private func generateChatGPTPrompt(from text: String) -> String {
        var prompt = basePrompt + historyListText + "\nUser: \(text)" + selectedLanguageString + "\nChatGPT:"
        print(prompt)
        if prompt.count > (4000 * 4) { // equivalent of 4 tokes
            _ = historyList.dropFirst()
            prompt = generateChatGPTPrompt(from: text)
        }
        return prompt
    }
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let jsonBody: [String: Any] = [
            
            "model": "text-davinci-003",
            "temperature" : 0.5,
            "max_tokens" : 500,
            "prompt" : generateChatGPTPrompt(from: text),
            "stop" : [
                "\n\n\n",
                "<|im_end|>"
            ],
            "stream" : stream
        ]
        
        return try JSONSerialization.data(withJSONObject: jsonBody)
    }
}

extension ChatGPTAPI {
    
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
            throw "Bad Response: \(httpResponse.statusCode)"
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    var streamText = ""
                    for try await line in result.lines {
                        if line.hasPrefix("data: "), let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? self.jsonDecoder.decode(CompletionResponse.self, from: data), let text = response.choices.first?.text {
                            streamText += text
                            continuation.yield(text)
                        }
                    }
                    self.historyList.append(streamText)
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
            throw "Bad Response: \(httpResponse.statusCode)"
        }
        
        do {
            let completionResponse = try self.jsonDecoder.decode(CompletionResponse.self, from: data)
            let responseText = completionResponse.choices.first?.text ?? ""
            self.historyList.append(responseText)
            return responseText
        } catch {
            throw error
        }
        
    }
}

extension String: Error {}
