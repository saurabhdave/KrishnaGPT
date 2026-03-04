//
//  KrishnaGPT.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/6/23.
//

import SwiftUI

@main
struct KrishnaGPTApp: App {
    @StateObject private var vm: ChatGPTViewModel

    init() {
#if DEBUG
        if AppConfig.apiKey.isEmpty {
            assertionFailure("""
            OPENAI_API_KEY is empty.
            Set OPENAI_API_KEY in Scheme > Run > Environment Variables for local development.
            """)
        }
#endif

        let api = ChatGPTAPI(
            apiKey: AppConfig.apiKey,
            model: AppConfig.model,
            systemPrompt: AppConfig.systemPrompt,
            temperature: AppConfig.temperature
        )
        _vm = StateObject(wrappedValue: ChatGPTViewModel(api: api))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(viewModel: vm)
            }
        }
    }
}
