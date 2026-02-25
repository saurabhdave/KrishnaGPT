//
//  MessageRowView.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import SwiftUI

struct MessageRowView: View, Equatable {
    static func == (lhs: MessageRowView, rhs: MessageRowView) -> Bool {
        lhs.message == rhs.message && lhs.isLightMode == rhs.isLightMode
    }
    
    let message: MessageRow
    let isLightMode: Bool
    let retryCallback: (MessageRow) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            messageRow(
                text: message.sendText,
                image: message.sendImage,
                isUser: true
            )
            
            if let text = message.responseText {
                messageRow(
                    text: text,
                    image: message.responseImage,
                    isUser: false,
                    responseError: message.responseError,
                    showDotLoading: message.isInteractingWithChatGPT
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
    
    private func messageRow(text: String, image: String, isUser: Bool, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            if !isUser {
                avatar(for: image)
            }
            
            if isUser {
                Spacer(minLength: 44)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                if !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .foregroundStyle(textForegroundColor(isUser: isUser))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
                
                if let error = responseError {
                    Text("Error: \(error)")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(isLightMode ? 0.14 : 0.2))
                        )
                    
                    Button("Regenerate response") {
                        retryCallback(message)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityHint("Retries generating the response for this message")
                }
                
                if showDotLoading {
                    DotsLoadingView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(bubbleBackground(isUser: isUser))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(bubbleBorderColor(isUser: isUser), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: bubbleShadowColor, radius: 8, x: 0, y: 3)
            
            if !isUser {
                Spacer(minLength: 44)
            }
            
            if isUser {
                avatar(for: image)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
    
    private func avatar(for image: String) -> some View {
        MessageRowImageView(image: image)
            .frame(width: 34, height: 34)
            .background(Circle().fill(isLightMode ? Color.white : Color.black.opacity(0.28)))
            .overlay(
                Circle()
                    .stroke(isLightMode ? Color.black.opacity(0.08) : Color.white.opacity(0.18), lineWidth: 1)
            )
    }
    
    private func bubbleBackground(isUser: Bool) -> some ShapeStyle {
        if isUser {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.23, green: 0.53, blue: 0.98),
                        Color(red: 0.19, green: 0.73, blue: 0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        
        return AnyShapeStyle(
            isLightMode
                ? Color.white
                : Color(red: 44/255, green: 46/255, blue: 56/255)
        )
    }
    
    private func textForegroundColor(isUser: Bool) -> Color {
        isUser ? .white : (isLightMode ? .black.opacity(0.9) : .white.opacity(0.95))
    }
    
    private func bubbleBorderColor(isUser: Bool) -> Color {
        if isUser {
            return Color.white.opacity(0.25)
        }
        
        return isLightMode ? Color.black.opacity(0.08) : Color.white.opacity(0.1)
    }
    
    private var bubbleShadowColor: Color {
        isLightMode ? Color.black.opacity(0.08) : Color.black.opacity(0.25)
    }
}

struct MessageRowView_Previews: PreviewProvider {
    
    static let message = MessageRow(
        isInteractingWithChatGPT: true, sendImage: "profile",
        sendText: "What is SwiftUI?",
        responseImage: "krishnaai",
        responseText: "SwiftUI is a user interface framework that allows developers to design and develop user interfaces for iOS, macOS, watchOS, and tvOS applications using Swift, a programming language developed by Apple Inc.")
    
    static var previews: some View {
        MessageRowView(message: message, isLightMode: false) { messageRow in
            
        }.previewLayout(.sizeThatFits)
            .background(Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
    }
}
