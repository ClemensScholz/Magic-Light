//
//  Magic_Light_App.swift
//  Magic Light 2.0
//
//  Created by Clemens on 17.01.21.
//

import SwiftUI

@main
struct Magic_Light_App: App {
    
    @ObservedObject var homeManager = HomeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(homeManager: homeManager)
        }
    }
}
