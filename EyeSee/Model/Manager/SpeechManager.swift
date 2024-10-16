//
//  SpeechManager.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/17.
//

import Speech
import SwiftUI
import Combine

class SpeechManager: ObservableObject {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    
    private var isTapInstalled: Bool = false // 追蹤 Tap 是否已安裝
    
    func checkPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                    case .authorized:
                        completion(true)
                    case .denied, .restricted, .notDetermined:
                        completion(false)
                    @unknown default:
                        completion(false)
                }
            }
        }
    }
    
    func startRecording(textString: @escaping ((String) -> ())) {
        guard !isRecording else {
            print("Already recording")
            return
        }
        
        checkPermissions { [weak self] authorized in
            guard let self = self else { return }
            if !authorized {
                print("Speech recognition not authorized")
                textString("無法啟動語音識別，請檢查權限設定。")
                return
            }
            
            if self.recognitionTask != nil {
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
            }
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("audioSession properties weren't set because of an error.")
                return
            }
            
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = self.recognitionRequest else {
                fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
            }
            
//            recognitionRequest.shouldReportPartialResults = false
            recognitionRequest.requiresOnDeviceRecognition = false
            
            self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest,
                                                                          resultHandler: { result, error in
                var isFinal = false
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }
                
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    if self.isTapInstalled {
                        self.audioEngine.inputNode.removeTap(onBus: 0)
                        self.isTapInstalled = false
                    }
                    
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    self.isRecording = false
                }
            })
            
            let recordingFormat = self.audioEngine.inputNode.outputFormat(forBus: 0)
            
            self.audioEngine.reset()
            
            self.audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }
            self.isTapInstalled = true // 標記 Tap 已安裝
            
            self.audioEngine.prepare()
            
            do {
                try self.audioEngine.start()
                self.isRecording = true
                textString("Say something, I'm listening!")
            } catch {
                print("audioEngine couldn't start because of an error.")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else {
            print("Not recording")
            return
        }
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }
}
