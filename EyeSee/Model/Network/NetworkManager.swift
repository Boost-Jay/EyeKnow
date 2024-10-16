//
//  NetworkManager.swift
//  EyeSee
//
//  Created by Wang Allen on 2023/6/29.
//

import Foundation
import SwiftHelpers

final class NetworkManager: NSObject {
    
    static let shared = NetworkManager()
    
    func requestData<E, D>(method: HTTP.Method,
                           server: NetworkConfiguration.Server,
                           path: APIPath,
                           parameters: E) async throws -> D where E: Encodable, D: Decodable {
        let urlRequest = try buildURLRequest(method, server, path, parameters)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let response = (response as? HTTPURLResponse) else {
            throw NetworkError.badResponse
        }
        let statusCode = response.statusCode
        guard let status = HTTP.StatusCode(rawValue: statusCode) else {
            throw NetworkError.unknownStatus(.unknown)
        }
        
        guard status == .ok else {
            throw NetworkError.unexpected(status)
        }
        do {
            let result = try JSONDecoder().decode(D.self, from: data)
            
            #if DEBUG
            printNetworkProgress(urlRequest, parameters, result)
            #endif
            
            return result
        } catch {
            print("=====================ERROR DATA=====================")
            print(data.base64EncodedString().utf8)
            print("====================================================")
            throw NetworkError.jsonDecodedFailed(error as! DecodingError)
        }
    }
    
    func requestUploadFileData<D>(method: HTTP.Method,
                                  server: NetworkConfiguration.Server,
                                  path: APIPath,
                                  fileURL: URL) async throws -> D where D: Decodable {
        let urlRequest = try buildUploadFileURLRequest(.post, .uploadPDF, fileURL)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let response = (response as? HTTPURLResponse) else {
            throw NetworkError.badResponse
        }
        let statusCode = response.statusCode
        guard let status = HTTP.StatusCode(rawValue: statusCode) else {
            throw NetworkError.unknownStatus(.unknown)
        }
        
        guard status == .ok else {
            throw NetworkError.unexpected(status)
        }
        do {
            let result = try JSONDecoder().decode(D.self, from: data)
            
            print("---------------Response----------------")
            print(result)
            print("=======================================")
            #if DEBUG
//            printNetworkProgress(urlRequest, parameters, result)
            #endif
            
            return result
        } catch {
            print("=====================ERROR DATA=====================")
            print(data.base64EncodedString().utf8)
            print("====================================================")
            throw NetworkError.jsonDecodedFailed(error as! DecodingError)
        }
    }
    
    private func buildURLRequest<E>(_ method: HTTP.Method,
                                    _ server: NetworkConfiguration.Server,
                                    _ path: APIPath,
                                    _ parameters: E) throws -> URLRequest where E: Encodable {
        let host = server.host
        guard let url = URL(string: host + path.rawValue) else {
            throw NetworkError.badURLFormat
        }
        var urlRequest = URLRequest(url: url, timeoutInterval: 50)
        urlRequest.httpMethod = method.rawValue
        
        let contentType = HTTP.HeaderFields.contentType.rawValue
        let json = HTTP.ContentType.json.rawValue
        
        switch server {
        case .openai:
            let authentication = HTTP.HeaderFields.authentication.rawValue
            let openaiAPIKey = NetworkConfiguration.openaiAPIKey
            
            urlRequest.allHTTPHeaderFields = [
                contentType : json,
                authentication : "Bearer \(openaiAPIKey)"
            ]
        case .localRAG:
            urlRequest.allHTTPHeaderFields = [
                contentType : json
            ]
        }
        
        switch method {
        case .get:
            do {
                let dict = try parameters.toDictionary()
                let parameters = dict as? [String : String] ?? [:]
                urlRequest.url = buildURLWithQueryItems(url: urlRequest.url?.absoluteString ?? "",
                                                        parameters: parameters)
            } catch {
                throw JSON.JSONEncodeError.encodableToDictFailed
            }
        default:
            do {
                urlRequest.httpBody = try JSON.toJsonData(data: parameters)
            } catch {
                throw NetworkError.badRequestJSONBody
            }
        }
        return urlRequest
    }
    
    private func buildUploadFileURLRequest(_ method: HTTP.Method,
                                           _ path: APIPath,
                                           _ fileURL: URL) throws -> URLRequest {
        let host = NetworkConfiguration.Server.localRAG.host
        guard let url = URL(string: host + path.rawValue) else {
            throw NetworkError.badURLFormat
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        // TODO: 待完成上傳檔案的 URLRequest
        
        // 設置請求頭
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)",
                            forHTTPHeaderField: "Content-Type")
        
        // 創建 multipart/form-data 主體
        let pdfData = try Data(contentsOf: fileURL)
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"document.pdf\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
                
        urlRequest.httpBody = body
        
        return urlRequest
    }
    
    private func buildURLWithQueryItems(url: String, parameters: [String : String] = [:]) -> URL? {
        guard var urlComponents = URLComponents(string: url) else { return nil }
        urlComponents.queryItems = []
        parameters.forEach { key, value in
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        return urlComponents.url
    }
    
    private func printNetworkProgress<E, D>(_ urlRequest: URLRequest,
                                            _ parameters: E,
                                            _ results: D) where E: Encodable, D: Decodable {
        #if DEBUG
        print("=======================================")
        print("- URL: \(urlRequest.url?.absoluteString ?? "")")
        print("- Header: \(urlRequest.allHTTPHeaderFields ?? [:])")
        print("---------------Request-----------------")
        print(parameters)
        print("---------------Response----------------")
        print(results)
        print("=======================================")
        #endif
    }
}
