//
//  ChatFooterView.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import SwiftHelpers
import SwiftUI
import AVFoundation

struct ChatFooterView: View {
    
    // Environment
    @Environment(\.modelContext) private var modelContext
    
    // ViewModel
    @State private var vm = ChatFooterViewViewModel()
    @ObservedObject private var speechManager = SpeechManager()

    // View Properties
    @State private var inputMessage: String = ""
    @State private var isChooseFile: Bool = false
    @State private var showImportFileError: Bool = false
    @State private var showImportFileSuccess: Bool = false
    @State private var importingErrorMessage: String = ""
    @State private var pdfFileURL: URL? = nil
    @State private var speechString: String = ""
    @Binding var selectedIndex: Int
    @State private var isRecording = false

    var body: some View {
        VStack {
            buildInputView()
        }
    }
}

#Preview {
    ChatFooterView(selectedIndex: .constant(0))
}

// MARK: - @ViewBuilder

fileprivate extension ChatFooterView {
    
    @ViewBuilder
    func buildInputView() -> some View {
        HStack {
            switch AppDefine.ChatInputMethod.allCases[selectedIndex] {
            case .text:
                buildKeyboardInput()
            case .voice:
                buildVoiceInput()
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
            }
        }
    }
    
    @ViewBuilder
    func buildKeyboardInput() -> some View {
        TextField("Send a message...", text: $inputMessage)
            .textFieldStyle(.roundedBorder)
        buildChooseFileBtn()
        buildSendChatBtn()
    }
    
    @ViewBuilder
    func buildVoiceInput() -> some View {
        buildUseVoiceBtn()
        buildChooseFileBtn()
//        buildSendChatBtn()
    }
    
    @ViewBuilder
    func buildUseVoiceBtn() -> some View {
        Button {
            if speechManager.isRecording {
                Task {
                    let question = Chat(content: speechManager.recognizedText, isReply: true)
                    try vm.saveChat(context: modelContext, chat: question)
                    
                    let res = try await vm.send(question: question.content)
                    
                    let reply = Chat(content: "Reply:\n\(res.answer)", isReply: false)
                    SpeechSynthesizerManager.shared.speechText(text: res.answer)
                    try vm.saveChat(context: modelContext, chat: reply)
                }
           } else {
               speechManager.startRecording { message in
                   print(message)
                   speechString = message
               }
           }
        } label: {
            Image(symbols: .musicMic)
        }
    }
    
    @ViewBuilder
    func buildChooseFileBtn() -> some View {
        Button {
            // 選擇 PDF 檔案
            isChooseFile.toggle()
        } label: {
            Image(symbols: .link)
        }
        .fileImporter(isPresented: $isChooseFile, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let fileURL):
                
                if let url = try? result.get() {
                    guard url.startAccessingSecurityScopedResource() else {
                        print("無法訪問文件")
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // 複製文件到應用沙盒
                    let destination = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    try? FileManager.default.copyItem(at: url, to: destination)
                    
                    // 上傳到後端
                    Task {
                        _ = try await vm.upload(fileURL: destination)
                        showImportFileSuccess.toggle()
                    }
                }
            case .failure(let error):
                importingErrorMessage = error.localizedDescription
                print(importingErrorMessage)
                showImportFileError.toggle()
            }
        }
        .alert("Importing Error", isPresented: $showImportFileError) {
            Button {
                showImportFileError = false
                isChooseFile = false
            } label: {
                Text("Close")
            }
        } message: {
            Text("Can't import file from Document.\nError: \(importingErrorMessage)")
        }
        .alert("Importing Success", isPresented: $showImportFileSuccess) {
            Button {
                showImportFileSuccess = false
                isChooseFile = false
            } label: {
                Text("Close")
            }
        } message: {
            Text("File imported successfully.")
        }
        
    }
    
    @ViewBuilder
    func buildSendChatBtn() -> some View {
        Button {
//            // 發送訊息
            Task {
                let question = Chat(content: inputMessage, isReply: true)
                try vm.saveChat(context: modelContext, chat: question)
                inputMessage = ""
                
                let res = try await vm.send(question: question.content)
                
                let reply = Chat(content: "Reply:\n\(res.answer)", isReply: false)
                try vm.saveChat(context: modelContext, chat: reply)
            }
        } label: {
            Image(symbols: .paperplane)
        }
    }
}
