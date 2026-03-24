//
//  Strings.swift
//  KrishnaGPT
//
//  Constants enum backed by String Catalog (Localizable.xcstrings).
//  Usage: Strings.Chat.navigationTitle, Strings.Accessibility.sendMessageHint, etc.
//

import Foundation

enum Strings {

    // MARK: - Chat Screen

    enum Chat {
        static let navigationTitle = String(localized: "chat.navigationTitle", defaultValue: "Bhagavad Gita AI")
        static let inputPlaceholder = String(localized: "chat.inputPlaceholder", defaultValue: "Ask Shri Krishna...")
        static let emptyStateTitle = String(localized: "chat.emptyStateTitle", defaultValue: "Ask Krishna anything")
        static let emptyStateSubtitle = String(localized: "chat.emptyStateSubtitle", defaultValue: "Choose a question below or type your own")
    }

    // MARK: - Suggested Questions

    enum SuggestedQuestions {
        static let dharma = String(localized: "suggestedQuestions.dharma", defaultValue: "What is the meaning of dharma?")
        static let fearAndAnxiety = String(localized: "suggestedQuestions.fearAndAnxiety", defaultValue: "How do I overcome fear and anxiety?")
        static let karma = String(localized: "suggestedQuestions.karma", defaultValue: "What does the Gita say about karma?")
        static let innerPeace = String(localized: "suggestedQuestions.innerPeace", defaultValue: "How to find inner peace?")

        static let all: [String] = [dharma, fearAndAnxiety, karma, innerPeace]
    }

    // MARK: - Actions (button labels, menu labels)

    enum Actions {
        static let clear = String(localized: "actions.clear", defaultValue: "Clear")
        static let language = String(localized: "actions.language", defaultValue: "Language")
        static let pickLanguage = String(localized: "actions.pickLanguage", defaultValue: "Pick a language")
        static let sendMessage = String(localized: "actions.sendMessage", defaultValue: "Send message")
        static let regenerateResponse = String(localized: "actions.regenerateResponse", defaultValue: "Regenerate response")
        static let scanText = String(localized: "actions.scanText", defaultValue: "Scan text from camera")
    }

    // MARK: - Accessibility

    enum Accessibility {
        static let clearHint = String(localized: "accessibility.clearHint", defaultValue: "Clears all messages in the conversation and starts fresh")
        static let changeLanguage = String(localized: "accessibility.changeLanguage", defaultValue: "Change conversation language")

        static func currentLanguageHint(_ language: String) -> String {
            "Currently set to \(language)"
        }

        static let messageInput = String(localized: "accessibility.messageInput", defaultValue: "Message input")
        static let messageInputHint = String(localized: "accessibility.messageInputHint", defaultValue: "Enter your question or message to ask Krishna")
        static let sendMessageHint = String(localized: "accessibility.sendMessageHint", defaultValue: "Sends your message to Krishna for a response")
        static let suggestedQuestion = String(localized: "accessibility.suggestedQuestion", defaultValue: "Suggested question")
        static let userMessage = String(localized: "accessibility.userMessage", defaultValue: "Your message")
        static let krishnaResponse = String(localized: "accessibility.krishnaResponse", defaultValue: "Krishna response")
        static let regenerateHint = String(localized: "accessibility.regenerateHint", defaultValue: "Retries generating the response for this message due to an error")
        static let scanTextHint = String(localized: "accessibility.scanTextHint", defaultValue: "Opens the camera to scan text and insert it into the message")
        static let loading = String(localized: "accessibility.loading", defaultValue: "Loading")
        static let pleaseWait = String(localized: "accessibility.pleaseWait", defaultValue: "Please wait")
    }

    // MARK: - Errors

    enum Errors {
        static func responseError(_ error: String) -> String {
            "Error: \(error)"
        }

        static let previewUnavailable = String(localized: "errors.previewUnavailable", defaultValue: "Preview unavailable — check API config")
        static let apiKeyMissing = String(localized: "errors.apiKeyMissing", defaultValue: """
            OPENAI_API_KEY is empty.
            Create Configuration/Secrets.xcconfig from Configuration/Secrets.xcconfig.template
            and set your OPENAI_API_KEY value.
            """)
    }
}
