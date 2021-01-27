//
//  HomeManager.swift
//  Magic Light 2.0
//
//  Created by Clemens on 17.01.21.
//

import SwiftUI
import HomeKit

class HomeManager: NSObject, HMHomeManagerDelegate, ObservableObject {
   
    @Published var lightbulb: LightbulbModel?
    @Published var reachable = false
    
    var manager: HMHomeManager
    
    override init() {
        self.manager = HMHomeManager()
        super.init()
        self.manager.delegate = self
    }
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        print("DEBUG: Updated Homes!")
        
        guard let device = manager.primaryHome?.accessories.first(where: { $0.name == "Lightbulb" }) else {
            print("ERROR: Accessory not found!")
            return
        }
        
        for s in device.services {
            if (s.isUserInteractive) {
                print("DEBUG: user interactive service is \(s.localizedDescription)")
                
                var power = HMCharacteristic()
                var brightness = HMCharacteristic()
                var hue = HMCharacteristic()
                
                for c in s.characteristics {
                    if (c.localizedDescription == "Power State") {
                        power = c
                    } else if (c.localizedDescription == "Brightness") {
                        brightness = c
                    } else if (c.localizedDescription == "Hue") {
                        hue = c
                    } else if (c.localizedDescription == "Saturation") {
                        c.writeValue(50) { (_ : Error?) in
                            print("DEBUG: Saturation set to 50")
                        }
                    }
                }
                
                self.lightbulb = LightbulbModel(power: power, brightness: brightness, hue: hue)
            }
        }
        
        if (device.isReachable) {
            self.reachable = true
        }
    }
}
