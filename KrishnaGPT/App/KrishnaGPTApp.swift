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
