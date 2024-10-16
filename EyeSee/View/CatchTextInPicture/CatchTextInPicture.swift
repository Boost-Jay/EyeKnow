//
//  CatchTextInPicture.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/20.
//

import SwiftUI
import VisionKit

struct CatchTextInPicture: View {
    @State private var isShowingDocumentCamera = false
    @State private var isChatGPTConnectError = false
    @State private var isLoading = false
    
    @State private var image: [UIImage] = []
    @State private var chatGPTError: Error?
    @State private var extractedText: String = ""
    
    let networkManager = NetworkManager.shared
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                
                Button {
                    isShowingDocumentCamera = true
                } label: {
                    if image.isEmpty {
                        // 使用 HStack 並內部添加 Spacer() 以確保內容居中
                        HStack {
                            Spacer()
                            Image(systemName: "doc.text.image")
                                .font(.system(size: 30))
                            Text("Import Document")
                                .font(.system(size: 30))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .frame(width: 250, height: 250)
                        .background(Color.purple)
                        .clipShape(Circle())
                        .shadow(radius: 30)
                        // 移除外部 Spacer()
                    } else {
                        // 當有圖片時，使用 ScrollView 顯示內容
                        ScrollView {
                            VStack(alignment: .center, spacing: 20) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "doc.text.image")
                                        .font(.system(size: 30))
                                    Text("Retake")
                                        .font(.system(size: 30))
                                    Spacer()
                                }
                                .foregroundColor(.purple)
                                
                                if isLoading {
                                    // 不顯示提取的文字，顯示載入動畫
                                } else {
                                    if let attributedText = try? AttributedString(markdown: extractedText) {
                                        Text(attributedText)
                                            .padding()
                                    } else {
                                        Text(extractedText)
                                            .padding()
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                Spacer()
            }
            
            // 載入中的動畫覆蓋在畫面正中間
            if isLoading {
                Color.black.opacity(0.4) // 半透明背景
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    
                    Text("載入中...")
                        .foregroundColor(.white)
                        .padding(.top, 5)
                }
                .frame(width: 150, height: 150)
            }
        }
        .fullScreenCover(isPresented: $isShowingDocumentCamera) {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VNDocumentCameraViewControllerRepresentable(scanResult: $image) { scannedImages in
                    if let firstImage = scannedImages.first {
                        chatGPTGenerateDes(captureImage: firstImage, question: "提取文本上的文字")
                    }
                }
                .edgesIgnoringSafeArea(.all) // 確保代表的 UIView 覆蓋整個螢幕
            }
        }
        
        // "我希望你能幫助我識別這張圖片上的所有地方的文字內容，如文字有缺失或是語句不夠流暢的地方，請以符合邏輯的觀點對此進行額外描述，如果沒有詞彙都正常就不用進行任何額外補充，就直接結束就行，只需要回覆圖片內容，不用作更多敘述。（注意！如果需進行額外補充，需要在每次開頭前都讓使用者能清楚該筆資料有被修改過）"
        
        
        .alert("錯誤",
               isPresented: $isChatGPTConnectError,
               presenting: chatGPTError) { error in
            
            Button {
                isChatGPTConnectError = false
            } label: {
                Text("OK")
            }
        }
    }
}

extension CatchTextInPicture {
    
    func chatGPTGenerateDes(captureImage: UIImage, question: String) {
        guard captureImage.uiImageToBase64Str() != nil else {
            print("Failed to convert image to Base64 string.")
            return
        }
        
        // 調整對比度，這裡將對比度提高到1.5，您可以根據需要調整這個值
        guard let highContrastImage = captureImage.adjustedContrast(by: 1.5),
              let highContrastBase64Str = highContrastImage.uiImageToBase64Str() else {
            print("Failed to adjust contrast or convert image to Base64 string.")
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.extractedText = "" // 清空之前的文字
        }
        
        Task {
            do {
                let gptResponse = try await callAPIToChatGPTV4(question: question,
                                                               imageBase64Str: highContrastBase64Str)
                var combineStr = ""
                gptResponse.choices.forEach { choiceObjc in
                    combineStr.append(choiceObjc.message.content)
                }
                extractedText = combineStr
                
                // 語音反饋
                DispatchQueue.main.async {
                    SpeechSynthesizerManager.shared.speechText(text: extractedText)
                }
                
            } catch {
                isChatGPTConnectError = true
                chatGPTError = error
                print(chatGPTError!)
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func callAPIToChatGPTV4(question: String,
                            imageBase64Str: String) async throws -> ChatGPT4VisionResponse {
        
        let content1 = Content(type: "text", text: question)
        let imageUrl = ImageUrl(url: "data:image/jpeg;base64,\(imageBase64Str)", detail: "low")
        let content2 = Content(type: "image_url", image_url: imageUrl)
        let totalContent = [content1, content2]
        
        let message = RequestMessages(role: "user", content: totalContent)
        
        let request = ChatGPT4VisionRequest(model: "gpt-4o",
                                            messages: [message],
                                            maxTokens: 1000)
        
        do {
            let response: ChatGPT4VisionResponse = try await networkManager.requestData(method: .post,
                                                                                        server: .openai,
                                                                                        path: .chatGPT,
                                                                                        parameters: request)
            return response
        } catch {
            throw error
        }
    }
}
