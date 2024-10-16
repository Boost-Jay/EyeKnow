//
//  ChatFooterViewViewModel.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import SwiftData
import SwiftUI

final class ChatFooterViewViewModel {
    
    func saveChat(context: ModelContext, chat: Chat) throws {
        guard !chat.content.isEmpty else {
            return
        }
        try DatabaseManager.shared.save(context: context, model: chat)
    }
    
    func send(question: String) async throws -> RAGResponse {
        let request = RAGRequest(question: question)
        let result: RAGResponse = try await NetworkManager.shared.requestData(method: .post,
                                                                              server: .localRAG,
                                                                              path: .ragQA,
                                                                              parameters: request)
        return result
    }
    
    func upload(fileURL: URL) async throws -> String {
        
        let result: UploadFileResponse = try await NetworkManager.shared.requestUploadFileData(method: .post,
                                                                                               server: .localRAG,
                                                                                               path: .uploadPDF,
                                                                                               fileURL: fileURL)
                                                                                               
        return result.message
    }      
}
