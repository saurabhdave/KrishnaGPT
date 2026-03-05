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
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if AppConfig.apiKey.isEmpty && !isRunningTests {
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
        _vm = StateObject(wrappedValue: ChatGPTViewModel(service: api))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(viewModel: vm)
            }
        }
    }
}
