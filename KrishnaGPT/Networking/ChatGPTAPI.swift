//
//  ChatGPTAPI.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation

final class ChatGPTAPI {
    private enum APIError: LocalizedError {
        case emptyAPIKey
        case invalidResponse
        case badResponse(statusCode: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .emptyAPIKey:
                return "Missing OpenAI API key."
            case .invalidResponse:
                return "Invalid response from server."
            case let .badResponse(statusCode, message):
                if message.isEmpty {
                    return "Bad Response: \(statusCode)"
                }
                return "Bad Response: \(statusCode), \(message)"
            }
        }
    }

    private enum Constants {
        static let endpoint = "https://api.openai.com/v1/responses"
        // Conservative bound used to keep message history from growing unbounded.
        static let maxContextCharacters = 16_000
        static let maxHistoryItems = 100
    }

    private let systemPrompt: String
    private let temperature: Double
    private let model: String

    private var apiKey: String
    private let urlSession: URLSession
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()

    private var urlRequest: URLRequest {
        let url = URL(string: Constants.endpoint)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        return urlRequest
    }

    private var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)",
            "Accept": "application/json, text/event-stream"
        ]
    }

    private var selectedLanguage: LanguageType = .english
    private var selectedLanguageString: String {
        "\nAnswer in \(selectedLanguage) and do not answer as the user."
    }

    private var historyList = [Message]()

    init(
        apiKey: String,
        model: String = "gpt-4.1-mini",
        systemPrompt: String = "You are Krishna, answer according to the 18 chapters and 700 verses of the Bhagavad Gita, which contains life lessons on morality, strength, discipline and spirituality with relevent emoji. Professionally respond conversationally from Bhagavad Geeta and the chapter and verse labeled '1'. and '2.'.",
        temperature: Double = 0.5,
        urlSession: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.systemPrompt = systemPrompt
        self.temperature = temperature
        self.urlSession = urlSession
    }

    private func generateConversationHistory(from text: String) -> [Message] {
        let userMessage = Message(role: "user", content: text + selectedLanguageString)
        var trimmedHistory = historyList
        var messages = trimmedHistory + [userMessage]

        while messages.contentCount > Constants.maxContextCharacters, !trimmedHistory.isEmpty {
            // Remove oldest user-assistant pair if available.
            trimmedHistory.removeFirst(min(2, trimmedHistory.count))
            messages = trimmedHistory + [userMessage]
        }

        historyList = trimmedHistory
        return messages
    }

    private func makeInputItems(from messages: [Message]) -> [ResponseInputItem] {
        messages.map { message in
            ResponseInputItem(
                role: message.role,
                content: message.content
            )
        }
    }

    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let conversation = generateConversationHistory(from: text)
        let request = ResponsesRequest(
            model: model,
            instructions: systemPrompt,
            input: makeInputItems(from: conversation),
            stream: stream,
            temperature: temperature
        )
        return try jsonEncoder.encode(request)
    }

    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            var errorMessage = ""
            if let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
                errorMessage = errorResponse.message
            } else if let rawError = String(data: data, encoding: .utf8) {
                errorMessage = rawError
            }
            throw APIError.badResponse(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }

    private func decodeResponseText(from data: Data) throws -> String {
        let response = try jsonDecoder.decode(ResponsesAPIResponse.self, from: data)
        let messageItems = response.output.filter { $0.type == "message" || $0.type == nil }
        let outputContents = messageItems.flatMap { $0.content ?? [] }
        let outputTextItems = outputContents.filter { $0.type == "output_text" || $0.type == nil }
        let text = outputTextItems.compactMap(\.text).joined()

        return text
    }
}

extension ChatGPTAPI {
    private func appendToHistoryList(userText: String, responseText: String) {
        self.historyList.append(.init(role: "user", content: userText))
        self.historyList.append(.init(role: "assistant", content: responseText))
        if historyList.count > Constants.maxHistoryItems {
            historyList.removeFirst(2)
        }
    }

    func setChatGPTLanguage(languageType: LanguageType) {
        self.selectedLanguage = languageType
    }

    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.emptyAPIKey
        }

        var urlReq = self.urlRequest
        urlReq.httpBody = try jsonBody(text: text)

        let (result, response) = try await urlSession.bytes(for: urlReq)

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            var errorPayloadLines: [String] = []
            for try await line in result.lines {
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                if payload.isEmpty || payload == "[DONE]" { continue }
                errorPayloadLines.append(payload)
            }
            let data = errorPayloadLines.joined(separator: "\n").data(using: .utf8) ?? Data()
            try validateHTTPResponse(response, data: data)
        }

        return AsyncThrowingStream<String, Error> { continuation in
            let streamTask = Task(priority: .userInitiated) { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                do {
                    var streamText = ""
                    for try await line in result.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                        if payload == "[DONE]" { break }
                        guard let data = payload.data(using: .utf8) else { continue }

                        if let errorResponse = try? self.jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
                            throw APIError.badResponse(statusCode: 500, message: errorResponse.message)
                        }

                        let event = try self.jsonDecoder.decode(ResponsesStreamEvent.self, from: data)
                        if event.type.contains("error"), let message = event.error?.message {
                            throw APIError.badResponse(statusCode: 500, message: message)
                        }

                        guard event.type == "response.output_text.delta",
                              let text = event.delta,
                              !text.isEmpty else { continue }

                        streamText += text
                        continuation.yield(text)
                    }

                    self.appendToHistoryList(userText: text, responseText: streamText)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                streamTask.cancel()
            }
        }
    }

    func sendMessage(_ text: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.emptyAPIKey
        }

        var urlReq = self.urlRequest
        urlReq.httpBody = try jsonBody(text: text, stream: false)

        let (data, response) = try await urlSession.data(for: urlReq)
        try validateHTTPResponse(response, data: data)

        let responseText = try decodeResponseText(from: data)
        self.appendToHistoryList(userText: text, responseText: responseText)
        return responseText
    }

    func deleteHistoryList() {
        self.historyList.removeAll()
    }
}
