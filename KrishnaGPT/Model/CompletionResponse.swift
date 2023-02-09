//
//  CompletionResponse.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation

struct Choice: Decodable {
    let text: String
}

struct CompletionResponse: Decodable {
    let choices: [Choice]
}
