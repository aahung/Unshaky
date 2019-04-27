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

    static let TOTAL_COUNT_KEY = "DISMISS_COUNT"
    static let DETAIL_COUNT_KEY = "DISMISS_COUNT_DETAIL"

    let nVirtualKey = Int(N_VIRTUAL_KEY)

    private var dismissCount = 0
    private var dismissCountDetail: [Int] = [Int]()
    var statString: String {
        get {
            return String(format: NSLocalizedString("Overall Statistic", comment: ""), dismissCount)
        }
    }

    override init() {
        super.init()

        dismissCount = defaults.integer(forKey: Counter.TOTAL_COUNT_KEY)
        dismissCountDetail = defaults.array(forKey: Counter.DETAIL_COUNT_KEY) as? [Int] ?? Array(repeating: 0, count: nVirtualKey)
        notifyObservers()
    }

    func increment(keyCode: Int32) {
        dismissCount += 1
        dismissCountDetail[Int(keyCode)] += 1
        notifyObservers()
    }

    func reset() {
        dismissCount = 0
        notifyObservers()
    }

    func save() {
        defaults.set(dismissCount, forKey: Counter.TOTAL_COUNT_KEY)
        defaults.set(dismissCountDetail, forKey: Counter.DETAIL_COUNT_KEY)
        defaults.synchronize()
    }

    func notifyObservers() {
        NotificationCenter.default.post(name: .counterUpdate, object: nil)
    }
}

extension Notification.Name {
    static let counterUpdate = Notification.Name("counter-update")
}
