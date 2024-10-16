//
//  SpeechSynthesizerManager.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/17.
//

import AVFoundation

class SpeechSynthesizerManager {
    
    static let shared = SpeechSynthesizerManager()
    var synthesizer = AVSpeechSynthesizer()
    
    func speechText(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        synthesizer.speak(utterance)
    }
}
