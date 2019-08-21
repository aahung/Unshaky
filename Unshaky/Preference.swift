//
//  Preference.swift
//  Unshaky
//
//  Created by Xinhong LIU on 8/20/19.
//  Copyright © 2019 Nested Error. All rights reserved.
//

import Cocoa

class Preference: NSObject {
    let defaults = UserDefaults.standard
    var enableds: [Bool]!
    var delays: [Int]!
    var keyCodes: [Int]!
    var keyboardLayout: String!
    let nVirtualKey = Int(N_VIRTUAL_KEY)

    override init() {
        super.init()
        loadPreference()
        KeyboardLayouts.shared().setKeyboardLayout(keyboardLayout)
    }

    func loadPreference() {
        keyboardLayout = defaults.string(forKey: "keyboardLayout") ?? KL_US
        
        guard let delays = defaults.array(forKey: "delays") else {
            defaults.set([Int](repeating: 0, count: nVirtualKey), forKey: "delays")
            loadPreference()
            return
        }
        guard let enableds = defaults.array(forKey: "enableds") else {
            defaults.set([Bool](repeating: true, count: nVirtualKey), forKey: "enableds")
            loadPreference()
            return
        }

        self.delays = [Int](repeating: 0, count: nVirtualKey)
        self.enableds = [Bool](repeating: true, count: nVirtualKey)
        for i in 0..<nVirtualKey {
            self.delays[i] = i >= delays.count ? 0 : delays[i] as! Int
            self.enableds[i] = i >= enableds.count ? true : enableds[i] as! Bool
        }

        keyCodes = Array(0..<nVirtualKey).filter({ (i) -> Bool in
            return KeyboardLayouts.shared().keyCodeToString()[NSNumber(value: i)] != nil
        }).sorted { (a, b) -> Bool in
            return KeyboardLayouts.shared().keyCodeToString()[NSNumber(value: a)]! < KeyboardLayouts.shared().keyCodeToString()[NSNumber(value: b)]!
        }
    }

    func setDelay(delay: Int, code: Int) {
        delays[code] = delay
        defaults.set(delays, forKey: "delays")
        ShakyPressPreventer.sharedInstance().loadKeyDelays()
    }

    func setDelayforAll(delay: Int) {
        for i in 0..<self.delays.count {
            setDelay(delay: delay, code: i)
        }
    }

    func setEnabled(enabled: Bool, code: Int) {
        enableds[code] = enabled
        defaults.set(enableds, forKey: "enableds")
        ShakyPressPreventer.sharedInstance().loadKeyDelays()
    }

    func setKeyboardLayout(keyboardLayout: String) {
        defaults.set(keyboardLayout, forKey: "keyboardLayout")
        KeyboardLayouts.shared().setKeyboardLayout(keyboardLayout)
    }
}
