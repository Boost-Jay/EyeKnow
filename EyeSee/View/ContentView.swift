//
//  ContentView.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/9.
//

//
//  ContentView.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/9.
//

import SwiftHelpers
import SwiftUI
import AVFAudio

struct ContentView: View {
    
    // Environment
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var detectedObjectsModel = DetectedObjectsModel()
    
    @State private var vm = ChatFooterViewViewModel()
    @State private var selectedTab: AppDefine.Tab = .yoloDetectObject
    @State private var navigationTitle = AppDefine.Tab.yoloDetectObject.title
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // 主要內容視圖
                    switch selectedTab {
                        case .yoloDetectObject:
                            YoloDetectObjectView(detectedObjectsModel: detectedObjectsModel)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onAppear {
                                    if speechManager.isRecording {
                                        speechManager.stopRecording()
                                    }
                                }
                        case .perceiveEnvironment:
                            PerceiveEnvironmentView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onAppear {
                                    if speechManager.isRecording {
                                        speechManager.stopRecording()

                                    }
                                }
                        case .rag:
                            RAGChatView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onAppear {
                                    if speechManager.isRecording {
                                        speechManager.stopRecording()

                                    }
                                }
                        case .catchTextInPicture:
                            CatchTextInPicture()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onAppear {
                                    if speechManager.isRecording {
                                        speechManager.stopRecording()

                                    }
                                }
                    }
                    
                    CustomTabBarView(selectedTab: $selectedTab)
                        .frame(height: 50)
                        .padding(.bottom, 10)
                    
                    // 語音觸發按鈕
                    Button(action: {
                        toggleListening()
                    }) {
                        Image(systemName: speechManager.isRecording ? "mic.fill" : "mic.slash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(speechManager.isRecording ? .red : .gray)
                            .padding()
                    }
                    .accessibilityLabel("語音導航")
                    .accessibilityHint("按下開始或停止語音導航")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(selectedTab.title)
            .onAppear {
                setupAudioSession()
                toggleListening()
            }
            .onChange(of: speechManager.recognizedText) { _, newValue in
                print(speechManager.recognizedText)
                
                guard !newValue.isEmpty else { return }
                navigateToPage(command: newValue)
            }
        }
    }
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func toggleListening() {
        if speechManager.isRecording {
            speechManager.stopRecording()
            speechManager.recognizedText = ""
            SpeechSynthesizerManager.shared.speechText(text: "已停止語音導航。")
        } else {
            speechManager.startRecording { text in
                // 可以在此處處理部分結果，例如顯示提示信息
                print(text)
//                navigateToPage(command: text)
                // 使用語音合成器回饋用戶
                SpeechSynthesizerManager.shared.speechText(text: "請說出您想前往的頁面。")
            }
        }
    }
    
    func navigateToPage(command: String) {
        let lowercasedCommand = command.lowercased()
        
        if lowercasedCommand.contains("物體") {
            selectedTab = .yoloDetectObject
        } else if lowercasedCommand.contains("環境") {
            selectedTab = .perceiveEnvironment
        } else if lowercasedCommand.contains("聊天") {
            selectedTab = .rag
        } else if lowercasedCommand.contains("文字") {
            selectedTab = .catchTextInPicture
        } else if lowercasedCommand.contains("周遭") {
            if selectedTab == .yoloDetectObject {
                // 获取最近 2 秒内的识别结果
                let recentObjects = detectedObjectsModel.detectedObjects.filter {
                    Date().timeIntervalSince($0.timestamp) <= 2
                }
                
                if recentObjects.isEmpty {
                    SpeechSynthesizerManager.shared.speechText(text: "周遭沒有偵測到物體")
                } else {
                    let descriptions = recentObjects.map { object in
                        let roundedDistance = Int(round(object.distance * 100))
                        return "\(object.name) \(roundedDistance)公分"
                    }
                    let speechText = descriptions.joined(separator: "，")
                    SpeechSynthesizerManager.shared.speechText(text: "您周遭有：" + speechText)
                }
            } else {
                SpeechSynthesizerManager.shared.speechText(text: "請先進入物體偵測頁面")
            }
        } else {
            // 未识别的指令，可以显示提示或忽略
//            print("未识别的指令: \(command)")
//            DispatchQueue.main.async {
//                SpeechSynthesizerManager.shared.speechText(text: "未识别的指令。请再试一次。")
//            }
        }
    }

}
