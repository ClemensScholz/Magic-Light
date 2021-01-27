//
//  CameraViewModel.swift
//  Magic Light
//
//  Created by Clemens on 17.01.21.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) ->  UIView {
     
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview.frame = view.frame
        
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
