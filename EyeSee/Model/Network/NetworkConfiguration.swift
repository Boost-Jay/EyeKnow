//
//  NetworkConfiguration.swift
//  EyeSee
//
//  Created by Wang Allen on 2023/6/29.
//

import Foundation
import SwiftHelpers

struct NetworkConfiguration {
    
    static let openaiAPIKey = "sk-Sl8iViLaRD-DeIBq-3DMKurTv3Wo99l-qgBOqIozesT3BlbkFJ34XbKZPYe5tmQn2YUqU-vLbve2TZFHKgTm6UX6PqwA"
    
    enum Scheme: String {
        
        case http = "http://"
        
        case https = "https://"
        
        case websocket = "ws://"
    }
    
    enum Server {
        
        /// OpenAI API Server
        case openai
        
        /// Local RAG Backend Server
        case localRAG
        
        var host: String {
            switch self {
            case .openai:
                return "https://api.openai.com"
            case .localRAG:
                return "http://192.168.1.128:8000"
            }
        }
    }
}

enum NetworkError: Error {
    
    /// 錯誤的 URL 格式
    case badURLFormat
    
    /// 錯誤的 URLRequest Body
    case badRequestJSONBody
    
    /// 錯誤的 HTTP Response
    case badResponse
    
    /// 無預期的 HTTP Status
    case unexpected(HTTP.StatusCode)
    
    /// 未知的 HTTP Status
    case unknownStatus(HTTP.StatusCode)
    
    /// JSON 解碼失敗
    case jsonDecodedFailed(DecodingError)
}

// API 的網址
enum APIPath: String {
    
    case chatGPT = "/v1/chat/completions"
    
    case ragQA = "/rag/qa"
    
    case uploadPDF = "/upload/file"
}
