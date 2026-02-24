//
//  MessageRowView.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import SwiftUI

struct MessageRowView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    let message: MessageRow
    let retryCallback: (MessageRow) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            messageRow(text: message.sendText, image: message.sendImage, bgColor: colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
            
            if let text = message.responseText {
                Divider()
                messageRow(text: text, image: message.responseImage, bgColor: colorScheme == .light ? .gray.opacity(0.1) : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 1), responseError: message.responseError, showDotLoading: message.isInteractingWithChatGPT)
                Divider()
            }
        }
    }
    
    func messageRow(text: String, image: String, bgColor: Color, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 24) {
            
            MessageRowImageView(image: image)
            
            VStack(alignment: .leading) {
                if !text.isEmpty {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
                
                if let error = responseError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                    
                    Button("Regenerate response") {
                        retryCallback(message)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.top)
                    .accessibilityHint("Retries generating the response for this message")
                }
                
                if showDotLoading {
                    DotsLoadingView()
                }
            }
        }// HSTACK
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
    }
}

struct MessageRowView_Previews: PreviewProvider {
    
    static let message = MessageRow(
        isInteractingWithChatGPT: true, sendImage: "profile",
        sendText: "What is SwiftUI?",
        responseImage: "krishnaai",
        responseText: "SwiftUI is a user interface framework that allows developers to design and develop user interfaces for iOS, macOS, watchOS, and tvOS applications using Swift, a programming language developed by Apple Inc.")
    
    static var previews: some View {
        MessageRowView(message: message) { messageRow in
            
        }.previewLayout(.sizeThatFits)
            .background(Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
    }
}
