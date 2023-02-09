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
    
    let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        chatListView
            .navigationTitle("🦚 Bhagavad Gita AI")
            .toolbar {
                Menu(content: {
                    Picker("Pick a language", selection: $viewModel.selectedLanguage) {
                        ForEach(LanguageType.allCases, id: \.self) { item in // 4
                            Text(item.rawValue.capitalized) // 5
                        }
                    }
                },
                     label: { Label ("Language", systemImage: "character.bubble") })
            }.disabled(viewModel.isInteractingWithChatGPT)
        
    }
    
    var chatListView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.messages) { message in
                            MessageRowView(message: message) { retryMessage in
                                Task { @MainActor in
                                    await viewModel.retry(message:retryMessage)
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                
                Divider()
                
                bottomView(image: "profile", proxy: proxy)
                
                Spacer()
            }// VSTACK
            .onChange(of: viewModel.messages.last?.responseText) { _ in
                scrollToBottom(proxy: proxy)
            }
        }// ScrollViewReader
        .background(colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
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
        guard let lastMessageID = viewModel.messages.last?.id else { return }
        proxy.scrollTo(lastMessageID, anchor: .bottomTrailing)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView(viewModel: ChatGPTViewModel(api: ChatGPTAPI(apiKey: KrishnaGPTApp.apiKey)))
        }
    }
}
