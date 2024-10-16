//
//  UploadFile.swift
//  EyeSee
//
//  Created by imac-3700 on 2024/9/27.
//

import Foundation

struct UploadFileRequest: Encodable {
    
    let file: String
}

struct UploadFileResponse: Decodable {
    
    let message: String
}
