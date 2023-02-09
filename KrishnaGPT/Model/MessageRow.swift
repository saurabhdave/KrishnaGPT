//
//  MessageRow.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation

struct MessageRow: Identifiable {
    
    let id = UUID()
    var isInteractingWithChatGPT: Bool
    
    let sendImage: String
    let sendText: String
    
    var responseImage: String
    var responseText: String
    
    var responseError: String?
}
