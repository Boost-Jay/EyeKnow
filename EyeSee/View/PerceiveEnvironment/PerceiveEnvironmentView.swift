//
//  PerceiveEnvironmentView.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/20.
//

import AVFoundation
import Speech
import SwiftUI

struct PerceiveEnvironmentView: View {
    
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var speechManager = SpeechManager()
    
    @State private var isChatGPTConnectError = false
    @State private var recordButtonStatus = false
    @State private var speechIsRecording = false
    @State private var chatGPTError: Error?
    @State private var speechString: String = ""
    @State private var captureImage: UIImage?
    @State private var imageDescribe: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            PerceiveEnvironmentViewModel(cameraManager: cameraManager,
                                         didFinishProcessingPhoto: { result in
                switch result {
                case .success(let photo):
                    if let data = photo.fileDataRepresentation() {
                        captureImage = UIImage(data: data)
                        chatGPTGenerateDes()
                    } else {
                        print("Error: no image data found")
                    }
                case .failure(let error):
                    isChatGPTConnectError = true
                    print(error)
                }
            }, speechManager: speechManager) { speechIsAvailable in
                recordButtonStatus = speechIsAvailable
            }
            
            VStack {
                Spacer()
                if speechString != "" {
                    Text(imageDescribe)
                        .foregroundStyle(Color.white)
                        .background(Color.black)
                        .opacity(0.8)
                        .clipShape( RoundedRectangle(
                            cornerRadius: 20
                        ))
                }
                if recordButtonStatus != true {
                    if speechIsRecording == true {
                        Button(action: {
                            speechManager.stopRecording()
                            speechIsRecording = false
                            cameraManager.capturePhoto()
                        }, label: {
                            Image(systemName: "stop.circle")
                                .font(.system(size: 72))
                                .foregroundStyle(.white)
                        })
                        .padding(.bottom)
                    } else {
                        Button(action: {
                            speechIsRecording = true
                            speechManager.startRecording { responseText in
                                print(responseText)
                                speechString = responseText
                            }
                        }, label: {
                            Image(systemName: "circle")
                                .font(.system(size: 72))
                                .foregroundStyle(.white)
                        })
                        .padding(.bottom)
                    }
                }
            }
        }
        .alert("錯誤",
               isPresented: $isChatGPTConnectError,
               presenting: chatGPTError) { error in
            Button {
                isChatGPTConnectError = false
                self.dismiss()
            } label: {
                Text("OK")
            }
        }
    }
    
    func chatGPTGenerateDes() {
        let base64Str = captureImage?.uiImageToBase64Str()
        Task {
            do {
                let gptResponse = try await cameraManager.callAPIToChatGPTV4(question: speechString + "幫我用繁體中文回答",
                                                                             imageBase64Str: base64Str!)
                var combineStr = ""
                gptResponse.choices.forEach { choiceObjc in
                    combineStr.append(choiceObjc.message.content)
                }
                imageDescribe = combineStr
                
                
                //                imageDescribe = "这张图片上是一个橙色的水果，看起来像是一个橙子。橙子表面有些凹凸不平的纹理，颜色鲜艳。它放置在白色的桌面上，周围似乎有一些物品，但不在焦点中所以不太清晰。通常情况下，一个中等大小的橙子大概含有60-80卡路里。橙子是一种富含维生素C、纤维和其他营养素的健康水果。它的成分主要包括水分、糖分、膳食纤维和多种维生素和矿物质。"
                
                DispatchQueue.main.async {
                    SpeechSynthesizerManager.shared.speechText(text: imageDescribe)
                }
                
            } catch {
                chatGPTError = error
                print(chatGPTError!)
            }
        }
    }
}

