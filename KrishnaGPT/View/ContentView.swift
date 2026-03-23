//
//  ContentView.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/6/23.
//

import SwiftUI
import UIKit

struct ContentView: View {

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: ChatGPTViewModel
    @FocusState var isTextFieldFocused: Bool
    @State private var lastAutoScrollCharacterCount = 0
    @State private var hapticImpact = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        chatListView
            .navigationTitle("Bhagavad Gita AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                Button {
                    Task {
                        await viewModel.clearMessages()
                    }
                } label: {
                    Label ("Clear", systemImage: "trash.slash")
                }
                .accessibilityHint("Clears all messages in the conversation and starts fresh")

                Menu(content: {
                    Picker("Pick a language", selection: $viewModel.selectedLanguage) {
                        ForEach(LanguageType.allCases, id: \.self) { item in
                            Text(item.rawValue.capitalized)
                        }
                    }
                },
                     label: { Label ("Language", systemImage: "character.bubble") })
                .accessibilityLabel("Change conversation language")
                .accessibilityHint("Currently set to \(viewModel.selectedLanguage.rawValue.capitalized)")
            }
            .disabled(viewModel.isInteractingWithChatGPT)
            .onAppear {
                hapticImpact.prepare()
            }

    }

    var chatListView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.messages) { message in
                            MessageRowView(message: message, isLightMode: colorScheme == .light) { retryMessage in
                                Task {
                                    await viewModel.retry(message: retryMessage)
                                }
                            }
                            .equatable()
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }

                Divider()

                bottomView(image: MessageRow.userImage, proxy: proxy)
            }// VSTACK
            .onChange(of: viewModel.messages.count) { _, _ in
                lastAutoScrollCharacterCount = 0
                guard !isVoiceOverRunning else { return }
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: viewModel.messages.last?.responseText) { _, newText in
                guard viewModel.isInteractingWithChatGPT, !isVoiceOverRunning else { return }

                let currentCharacterCount = newText?.count ?? 0
                let shouldAutoScroll = currentCharacterCount - lastAutoScrollCharacterCount >= 80
                if shouldAutoScroll {
                    lastAutoScrollCharacterCount = currentCharacterCount
                    scrollToBottom(proxy: proxy)
                }
            }
            .onChange(of: viewModel.isInteractingWithChatGPT) { _, isInteracting in
                if !isInteracting, !isVoiceOverRunning {
                    scrollToBottom(proxy: proxy, animated: true)
                }
            }
        }// ScrollViewReader
        .background(contentBackgroundColor)
    }

    func bottomView(image: String, proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .center, spacing: 8) {

            MessageRowImageView(image: image, isDecorative: true)

            HStack {
                TextField("Ask Shri Krishna", text: $viewModel.inputMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .accessibilityLabel("Message input")
                    .accessibilityHint("Enter your question or message to ask Krishna")

                ScanButton(text: $viewModel.inputMessage)
                    .frame(width: 56, height: 56, alignment: .leading)
            }
            .disabled(viewModel.isInteractingWithChatGPT)

            if viewModel.isInteractingWithChatGPT {
                DotsLoadingView()
                    .frame(width: 60, height: 30)
            } else {
                Button {
                    isTextFieldFocused = false
                    scrollToBottom(proxy: proxy)
                    Task {
                        await viewModel.sendTapped()
                    }
                    hapticImpact.impactOccurred()
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(45))
                        .font(.title2)
                }
                .accessibilityLabel("Send message")
                .accessibilityHint("Sends your message to Krishna for a response")
                .disabled(viewModel.isSendDisabled)
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(.horizontal, 16)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        scrollToBottom(proxy: proxy, animated: false)
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let lastMessageID = viewModel.messages.last?.id else { return }

        if animated {
            withAnimation {
                proxy.scrollTo(lastMessageID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastMessageID, anchor: .bottom)
        }
    }

    private var contentBackgroundColor: Color {
        colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5)
    }

    private var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
}

#Preview {
    NavigationStack {
        if let api = try? ChatGPTAPI(
            apiKey: AppConfig.apiKey,
            model: AppConfig.model,
            systemPrompt: AppConfig.systemPrompt,
            temperature: AppConfig.temperature
        ) {
            ContentView(viewModel: ChatGPTViewModel(service: api))
        } else {
            Text("Preview unavailable — check API config")
        }
    }
}
