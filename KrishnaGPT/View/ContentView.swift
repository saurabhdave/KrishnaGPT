//
//  ContentView.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/6/23.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: ChatGPTViewModel
    @FocusState var isTextFieldFocused: Bool
    @State private var lastAutoScrollCharacterCount = 0
    
    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        chatListView
            .navigationTitle("🦚 Bhagavad Gita AI")
            .toolbar {
                
                Button {
                    withAnimation {
                        viewModel.clearMessages()
                    }
                } label: {
                    Label ("Clear", systemImage: "trash.slash")
                }
                
                Menu(content: {
                    Picker("Pick a language", selection: $viewModel.selectedLanguage) {
                        ForEach(LanguageType.allCases, id: \.self) { item in
                            Text(item.rawValue.capitalized)
                        }
                    }
                },
                     label: { Label ("Language", systemImage: "character.bubble") })
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
                                Task { @MainActor in
                                    await viewModel.retry(message:retryMessage)
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
                
                bottomView(image: "profile", proxy: proxy)
            }// VSTACK
            .onChange(of: viewModel.messages.count) { _ in
                lastAutoScrollCharacterCount = 0
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: viewModel.messages.last?.responseText) { text in
                guard viewModel.isInteractingWithChatGPT else { return }
                
                let currentCharacterCount = text?.count ?? 0
                let shouldAutoScroll = currentCharacterCount - lastAutoScrollCharacterCount >= 80
                if shouldAutoScroll {
                    lastAutoScrollCharacterCount = currentCharacterCount
                    scrollToBottom(proxy: proxy)
                }
            }
            .onChange(of: viewModel.isInteractingWithChatGPT) { isInteracting in
                if !isInteracting {
                    scrollToBottom(proxy: proxy, animated: true)
                }
            }
        }// ScrollViewReader
        .background(contentBackgroundColor)
    }
    
    func bottomView(image: String, proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .center, spacing: 8) {
            
            MessageRowImageView(image: image)
            
            HStack {
                TextField("Ask Shri Krishna", text: $viewModel.inputMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                
                ScanButton(text: $viewModel.inputMessage)
                    .frame(width: 56, height: 56, alignment: .leading)
            }
            .disabled(viewModel.isInteractingWithChatGPT)
            
            if viewModel.isInteractingWithChatGPT {
                DotsLoadingView()
                    .frame(width: 60, height: 30)
            } else {
                Button {
                    Task { @MainActor in
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy)
                        await viewModel.sendTapped()
                        hapticImpact.impactOccurred()
                    }
                    
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(45))
                        .font(.system(size: 30))
                }
                .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView(
                viewModel: ChatGPTViewModel(
                    api: ChatGPTAPI(
                        apiKey: AppConfig.apiKey,
                        model: AppConfig.model,
                        systemPrompt: AppConfig.systemPrompt,
                        temperature: AppConfig.temperature
                    )
                )
            )
        }
    }
}
