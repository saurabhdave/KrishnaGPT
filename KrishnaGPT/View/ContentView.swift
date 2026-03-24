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
    @Bindable var viewModel: ChatGPTViewModel
    @FocusState var isTextFieldFocused: Bool
    @State private var lastAutoScrollCharacterCount = 0
    @State private var hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        chatListView
            .navigationTitle(Strings.Chat.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.automatic, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                
                Button {
                    Task {
                        await viewModel.clearMessages()
                    }
                } label: {
                    Label(Strings.Actions.clear, systemImage: "trash.slash")
                }
                .accessibilityHint(Strings.Accessibility.clearHint)
                
                Menu(content: {
                    Picker(Strings.Actions.pickLanguage, selection: $viewModel.selectedLanguage) {
                        ForEach(LanguageType.allCases, id: \.self) { item in
                            Text(item.rawValue.capitalized)
                        }
                    }
                },
                     label: { Label(Strings.Actions.language, systemImage: "character.bubble") })
                .accessibilityLabel(Strings.Accessibility.changeLanguage)
                .accessibilityHint(Strings.Accessibility.currentLanguageHint(viewModel.selectedLanguage.rawValue.capitalized))
                
                ScanButton(text: $viewModel.inputMessage)
            }
            .disabled(viewModel.isInteractingWithChatGPT)
            .onAppear {
                hapticImpact.prepare()
            }
        
    }
    
    var chatListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if viewModel.messages.isEmpty {
                    suggestedQuestionsView(proxy: proxy)
                } else {
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
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomView(image: MessageRow.userImage, proxy: proxy)
            }
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
    
    private func suggestedQuestionsView(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            Image(MessageRow.assistantImage)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            Text(Strings.Chat.emptyStateTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(colorScheme == .light ? .black.opacity(0.8) : .white.opacity(0.9))
            
            Text(Strings.Chat.emptyStateSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 10) {
                ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                    Button {
                        viewModel.inputMessage = question
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy)
                        Task {
                            await viewModel.sendTapped()
                        }
                        hapticImpact.impactOccurred()
                    } label: {
                        questionLabel(question)
                    }
                    .accessibilityLabel(Strings.Accessibility.suggestedQuestion)
                    .accessibilityValue(question)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }
    
    private func questionLabel(_ text: String) -> some View {
        let isLight = colorScheme == .light
        return Text(text)
            .font(.subheadline)
            .foregroundStyle(isLight ? Color.primary : Color.white.opacity(0.9))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isLight ? Color(.systemGray6) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    func bottomView(image: String, proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            HStack(alignment: .bottom, spacing: 0) {
                TextField(Strings.Chat.inputPlaceholder, text: $viewModel.inputMessage, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .focused($isTextFieldFocused)
                    .accessibilityLabel(Strings.Accessibility.messageInput)
                    .accessibilityHint(Strings.Accessibility.messageInputHint)
                    .disabled(viewModel.isInteractingWithChatGPT)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(colorScheme == .light ? Color(.systemGray6) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isTextFieldFocused
                            ? Color.accentColor.opacity(0.5)
                            : (colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.12)),
                        lineWidth: 1
                    )
            )

            if viewModel.isInteractingWithChatGPT {
                DotsLoadingView()
                    .frame(width: 40, height: 40)
            } else {
                Button {
                    isTextFieldFocused = false
                    scrollToBottom(proxy: proxy)
                    Task {
                        await viewModel.sendTapped()
                    }
                    hapticImpact.impactOccurred()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            .white,
                            viewModel.isSendDisabled
                                ? (colorScheme == .light ? Color(.systemGray4) : Color.white.opacity(0.15))
                                : Color.accentColor
                        )
                }
                .accessibilityLabel(Strings.Actions.sendMessage)
                .accessibilityHint(Strings.Accessibility.sendMessageHint)
                .disabled(viewModel.isSendDisabled)
                .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
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

// MARK: - Preview Helpers

private struct PreviewChatService: ChatNetworking {
    func sendMessageStream(text: String, language: LanguageType) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func sendMessage(_ text: String, language: LanguageType) async throws -> String { "" }
    func clearHistory() async {}
}

@MainActor
private func previewViewModel(messages: [MessageRow] = []) -> ChatGPTViewModel {
    let vm = ChatGPTViewModel(service: PreviewChatService())
    vm.messages = messages
    return vm
}

// MARK: - Previews

#Preview("Empty State") {
    NavigationStack {
        ContentView(viewModel: previewViewModel())
    }
}
#Preview("English Chat") {
    NavigationStack {
        ContentView(viewModel: previewViewModel(messages: [
            MessageRow(
                isInteractingWithChatGPT: false,
                sendImage: MessageRow.userImage,
                sendText: "What is the meaning of dharma?",
                responseImage: MessageRow.assistantImage,
                responseText: "Dharma, dear seeker, is the righteous path — the sacred duty that sustains cosmic and social order. As I teach in Bhagavad Gita 3.35: \"It is better to perform one's own duty imperfectly than to perform another's duty perfectly.\"\n\nDharma is not one-size-fits-all. It varies by your nature, stage of life, and circumstances. When you act in harmony with your true nature and responsibilities without selfish attachment, you walk the path of dharma."
            ),
            MessageRow(
                isInteractingWithChatGPT: false,
                sendImage: MessageRow.userImage,
                sendText: "How do I overcome fear and anxiety?",
                responseImage: MessageRow.assistantImage,
                responseText: "Fear arises from attachment to outcomes, Arjuna. In Bhagavad Gita 2.47: \"You have a right to perform your duties, but you are not entitled to the fruits of your actions.\"\n\nWhen you release your grip on results and anchor yourself in the present moment through steady practice, fear loses its hold. Cultivate equanimity — treat success and failure alike."
            )
        ]))
    }
    .preferredColorScheme(.dark)
}

#Preview("Hindi Chat") {
    NavigationStack {
        ContentView(viewModel: previewViewModel(messages: [
            MessageRow(
                isInteractingWithChatGPT: false,
                sendImage: MessageRow.userImage,
                sendText: "कर्म का अर्थ क्या है?",
                responseImage: MessageRow.assistantImage,
                responseText: "प्रिय साधक, कर्म का अर्थ है क्रिया — हर विचार, शब्द और कार्य जो आप करते हैं। भगवद्गीता 3.9 में मैंने कहा: \"यज्ञ के लिए किए गए कर्म के अतिरिक्त अन्य कर्म करने वाला मनुष्य कर्म के बंधन में बँधता है।\"\n\nकर्म केवल क्रिया नहीं, बल्कि उसके पीछे का भाव है। निष्काम कर्म — बिना फल की इच्छा के कर्तव्य पालन — यही मुक्ति का मार्ग है।"
            )
        ]))
    }
    .preferredColorScheme(.dark)
}

#Preview("Mandarin Chat") {
    NavigationStack {
        ContentView(viewModel: previewViewModel(messages: [
            MessageRow(
                isInteractingWithChatGPT: false,
                sendImage: MessageRow.userImage,
                sendText: "如何找到内心的平静？",
                responseImage: MessageRow.assistantImage,
                responseText: "亲爱的求道者，内心的平静来自于超越欲望与执著。在《薄伽梵歌》2.71中我说道：\"一个放弃了所有欲望、没有渴求、没有自我意识的人，才能获得平静。\"\n\n通过冥想和瑜伽的修行，你可以训练心灵保持稳定。当你不再被外在的得失所动摇，内在的宁静自然会显现。"
            )
        ]))
    }
    .preferredColorScheme(.dark)
}

