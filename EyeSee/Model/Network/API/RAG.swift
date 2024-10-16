//
//  RAG.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import Foundation

struct RAGRequest: Codable {
    
    let question: String
}

struct RAGResponse: Decodable {
    
    let answer: String
}
