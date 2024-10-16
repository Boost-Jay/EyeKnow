//
//  MPVolumeView.swift
//  EyeSee
//
//  Created by imac on 2024/9/21.
//

import MediaPlayer
import SwiftUI

struct VolumeViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let volumeView = MediaPlayer.MPVolumeView(frame: .zero)
        volumeView.isHidden = true
        view.addSubview(volumeView)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
