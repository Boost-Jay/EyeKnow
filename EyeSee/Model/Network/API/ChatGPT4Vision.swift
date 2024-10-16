//
//  ChatGPT4Vision.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/3/23.
//

import Foundation

struct ChatGPT4VisionRequest: Encodable {
    
    var model: String
    
    var messages: [RequestMessages]
    
    var maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        
        case model
        
        case messages
        
        case maxTokens = "max_tokens"
    }
}

struct RequestMessages: Encodable {
    
    var role: String
    
    var content: [Content]

}

struct Content: Encodable {
    
    var type: String
    
    var text: String?
    
    var image_url: ImageUrl?
}

struct ImageUrl: Encodable {
    
    var url: String
    
    var detail: String
}


struct ChatGPT4VisionResponse: Decodable {
    
    var id: String
    
    var object: String
    
    var created: Int
    
    var model: String
    
    var choices: [Choices]
    
    var usage: Usage
}

struct Choices: Decodable {
    
    var index: Int
    
    var message: ResponseMessage
    
    var finishReason: String
    
    enum CodingKeys: String, CodingKey {
        
        case index
        
        case message
        
        case finishReason = "finish_reason"
    }
}

struct ResponseMessage: Decodable {
    
    var role: String
    
    var content: String
    
}

struct Usage: Decodable {
    
    var promptTokens: Int
    
    var completionTokens: Int
    
    var totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        
        case promptTokens = "prompt_tokens"
        
        case completionTokens = "completion_tokens"
        
        case totalTokens = "total_tokens"
    }
}
