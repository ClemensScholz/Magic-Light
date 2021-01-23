//
//  LightbulbModel.swift
//  Magic Light 2.0
//
//  Created by Clemens on 17.01.21.
//

import HomeKit

class LightbulbModel {
    
    private var power: HMCharacteristic
    private var brightness: HMCharacteristic
    private var hue: HMCharacteristic
    
    init(power: HMCharacteristic, brightness: HMCharacteristic, hue: HMCharacteristic) {
        self.power = power
        self.brightness = brightness
        self.hue = hue
    }
    
    public func togglePower(state: Bool) {
        power.writeValue(state, completionHandler: {_ in
            print("DEBUG: Toogled power to \(state ? "On" : "Off" )")
        })
    }
    
    public func setHue(value: Int) {
        hue.writeValue(value, completionHandler: {_ in
            print("DEBUG: Updated hue to \(value)")
        })
    }
    
    public func setBrightness(value: Int) {
        brightness.writeValue(value, completionHandler: {_ in
            print("DEBUG: Updated hue to \(value)")
        })
    }
}
