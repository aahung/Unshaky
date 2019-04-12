//
//  Counter.swift
//  Unshaky
//
//  Created by Xinhong LIU on 4/11/19.
//  Copyright © 2019 Nested Error. All rights reserved.
//

import Cocoa

class Counter: NSObject {
    static let shared = Counter()

    let defaults = UserDefaults.standard
    private var dismissCount = 0
    var statString: String {
        get {
            return String(format: NSLocalizedString("Overall Statistic", comment: ""), dismissCount)
        }
    }

    override init() {
        super.init()

        dismissCount = defaults.integer(forKey: "DISMISS_COUNT")
        notifyObservers()
    }

    func increment() {
        dismissCount += 1
        notifyObservers()
    }

    func reset() {
        dismissCount = 0
        notifyObservers()
    }

    func save() {
        defaults.set(dismissCount, forKey: "DISMISS_COUNT")
        defaults.synchronize()
    }

    func notifyObservers() {
        NotificationCenter.default.post(name: .counterUpdate, object: nil)
    }
}

extension Notification.Name {
    static let counterUpdate = Notification.Name("counter-update")
}
