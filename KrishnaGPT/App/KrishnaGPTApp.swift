//
//  KrishnaGPT.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/6/23.
//

import SwiftUI

@main
struct KrishnaGPTApp: App {
    
    static let apiKey = "API_KEY" // Use your API Key

    @StateObject var vm = ChatGPTViewModel(api: ChatGPTAPI(apiKey: KrishnaGPTApp.apiKey))

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(viewModel: vm)
            }
        }
    }
}
