//
//  ContentView.swift
//  Magic Light 2.0
//
//  Created by Clemens on 17.01.21.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var homeManager: HomeManager
    @ObservedObject var camera: CameraModel
    
    init(homeManager: HomeManager) {
        camera = CameraModel(homeManager: homeManager)
        self.homeManager = homeManager
    }
    
    var body: some View {
        if (homeManager.lightbulb == nil) {
            VStack {
                Text("Lightbulb not found")
                    .font(.title)
                
                Text("Please add a Lightbulb to your accessories using the Home app.")
                    .multilineTextAlignment(.center)
            }
            .frame(width: 300, alignment: .center)
        } else {
            ZStack {
                CameraPreview(camera: camera)
                    .ignoresSafeArea(.all)
                VStack{
                    if (!homeManager.reachable) {
                        Text("Lightbulb is not reachable")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.top)
                    }
                    
                    Spacer()
                    
                    Button {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        print("DEBUG: Button pressed")
                        camera.toggleFlash()
                    } label: {
                        Image(systemName: camera.flashState ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.largeTitle)
                            .padding(.all)
                            .foregroundColor(camera.flashState ? Color.white : Color.black)
                    }
                    .background(camera.flashState ? Color.black : Color.white)
                    .cornerRadius(24)
                }
            }
        }
    }
}
