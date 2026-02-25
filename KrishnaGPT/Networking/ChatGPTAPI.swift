//
//  ChatGPTAPI.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation
import SDOpenAIClient

final class ChatGPTAPI {
    private enum Constants {
        static let maxContextCharacters = 16_000
        static let maxHistoryItems = 100
        static let requestTimeout: TimeInterval = 60
    }

    private let openAIClient: OpenAIClient
    private var selectedLanguage: LanguageType = .english

    init(
        apiKey: String,
        model: String = "gpt-4.1-mini",
        systemPrompt: String = "You are Krishna, answer according to the 18 chapters and 700 verses of the Bhagavad Gita, which contains life lessons on morality, strength, discipline and spirituality with relevent emoji. Professionally respond conversationally from Bhagavad Geeta and the chapter and verse labeled '1'. and '2.'.",
        temperature: Double = 0.5,
        urlSession: URLSession = .shared
    ) {
        let configuration = OpenAIClientConfiguration(
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            temperature: temperature,
            maxContextCharacters: Constants.maxContextCharacters,
            maxHistoryItems: Constants.maxHistoryItems,
            requestTimeout: Constants.requestTimeout,
            retryPolicy: .standard
        )

        self.openAIClient = OpenAIClient(
            configuration: configuration,
            session: urlSession
        )
    }

    private var languageInstruction: String {
        "Answer in \(selectedLanguage) and do not answer as the user."
    }
}

extension ChatGPTAPI {
    func setChatGPTLanguage(languageType: LanguageType) {
        selectedLanguage = languageType
    }

    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        try await openAIClient.stream(text, additionalInstructions: languageInstruction)
    }

    func sendMessage(_ text: String) async throws -> String {
        try await openAIClient.send(text, additionalInstructions: languageInstruction)
    }

    func deleteHistoryList() {
        Task {
            await openAIClient.clearHistory()
        }
    }
}
