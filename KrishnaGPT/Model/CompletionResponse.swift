//
//  CompletionResponse.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation

// MARK: - Legacy Chat Completions Models

struct Choice: Decodable {
    let message: Message
    let finishReason: String?
}

struct CompletionResponse: Decodable {
    let choices: [Choice]
    let usage: Usage?
}

struct Message: Codable {
    let role: String
    let content: String
}

extension Array where Element == Message {
    var contentCount: Int {
        reduce(0, { $0 + $1.content.count})
    }
}

struct Request: Codable {
    let model: String
    let temperature: Double
    let messages: [Message]
    let stream: Bool
}

struct ErrorRootResponse: Decodable {
    let error: ErrorResponse
}

struct ErrorResponse: Decodable {
    let message: String
    let type: String?
}

struct Usage: Decodable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
}

struct StreamChoice: Decodable {
    let finishReason: String?
    let delta: StreamMessage
    
}

struct StreamMessage: Decodable {
    let role: String?
    let content: String?
}

struct StreamCompletionResponse: Decodable {
    let choices: [StreamChoice]
}

// MARK: - Responses API Models

struct ResponsesRequest: Encodable {
    let model: String
    let instructions: String
    let input: [ResponseInputItem]
    let stream: Bool
    let temperature: Double
}

struct ResponseInputItem: Encodable {
    let role: String
    let content: String
}

struct ResponsesAPIResponse: Decodable {
    let output: [ResponseOutputItem]
}

struct ResponseOutputItem: Decodable {
    let type: String?
    let content: [ResponseOutputContent]?
}

struct ResponseOutputContent: Decodable {
    let type: String?
    let text: String?
}

struct ResponsesStreamEvent: Decodable {
    let type: String
    let delta: String?
    let error: ErrorResponse?
}
