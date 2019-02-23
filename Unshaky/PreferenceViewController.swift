//
//  PreferenceViewController.swift
//  Unshaky
//
//  Created by Xinhong LIU on 2018-07-10.
//  Copyright © 2018 Nested Error. All rights reserved.
//

import Cocoa

class PreferenceViewController: NSViewController,
                                NSTableViewDataSource,
                                NSTableViewDelegate {

    @IBOutlet weak var tableView: NSTableView!
    
    
    let defaults = UserDefaults.standard
    var delays: [Int]!
    var keyCodes: [Int]!
    let nVirtualKey = Int(N_VIRTUAL_KEY)
    var keyCodeToString = [Int: String]()
    
    override func viewDidLoad() {
        loadPreference()
        super.viewDidLoad()

        // sync ShakyPressPreventer.keyCodeToString to keyCodeToString
        for entry in ShakyPressPreventer.keyCodeToString {
            keyCodeToString[entry.key.intValue] = entry.value
        }

        keyCodes = Array(0..<nVirtualKey).filter({ (i) -> Bool in
            return keyCodeToString[i] != nil
        }).sorted { (a, b) -> Bool in
            return keyCodeToString[a]! < keyCodeToString[b]!
        }
    }
    
    func loadPreference() {
        guard let delays = defaults.array(forKey: "delays") else {
            defaults.set([Int](repeating: 0, count: nVirtualKey), forKey: "delays")
            loadPreference()
            return
        }
        self.delays = [Int](repeating: 0, count: nVirtualKey)
        for i in 0..<nVirtualKey {
            self.delays[i] = i >= delays.count ? 0 : delays[i] as! Int
        }
    }
    
    // MARK: NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return keyCodes.count
    }
    
    // MARK: NSTableViewDelegate
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if (tableColumn?.identifier)!.rawValue == "key" {
            guard let keyString = keyCodeToString[keyCodes[row]] else {
                return "UNDEFINED KEY"
            }
            return keyString
        }
        if (tableColumn?.identifier)!.rawValue == "delay" {
            return delays[keyCodes[row]]
        }
        return nil
    }
    
    @IBAction func delayEdited(_ sender: NSTextField) {
        let row = tableView.selectedRow
        guard let delayValue = Int(sender.stringValue) else {
            alertInvalidValue(invalidValue: sender.stringValue)
            return
        }
        self.delays[keyCodes[row]] = delayValue
        defaults.set(self.delays, forKey: "delays")
        ShakyPressPreventer.sharedInstance().loadKeyDelays()
    }

    @IBAction func ignoreExternalKeyboardToggled(_ sender: Any) {
        ShakyPressPreventer.sharedInstance()?.loadIgnoreExternalKeyboard()
    }

    @IBAction func workaroundForCmdSpaceToggled(_ sender: Any) {
        ShakyPressPreventer.sharedInstance()?.loadWorkaroundForCmdSpace()
    }

    @IBAction func aggressiveModeToggled(_ sender: Any) {
        ShakyPressPreventer.sharedInstance()?.loadAggressiveMode()
    }

    @IBOutlet weak var delayAllTextField: NSTextField!
    
    @IBAction func setAllDelays(_ sender: Any) {
        guard let delayFoAll = Int(delayAllTextField.stringValue) else {
            alertInvalidValue(invalidValue: delayAllTextField.stringValue)
            return
        }
        for i in 0..<self.delays.count {
            self.delays[i] = delayFoAll
        }
        self.tableView.reloadData()
        defaults.set(self.delays, forKey: "delays")
        ShakyPressPreventer.sharedInstance().loadKeyDelays()
    }

    func alertInvalidValue(invalidValue: String) {
        let alert = NSAlert()
        alert.messageText = "\"\(invalidValue)\" is not a valid delay. Please input an integer value."
        alert.runModal()
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case NSStoryboard.SegueIdentifier(rawValue: "export"):
            let destVC = segue.destinationController as! ExportImportViewController
            destVC.preferenceViewController = self
            destVC.mode = .Export
        case NSStoryboard.SegueIdentifier(rawValue: "import"):
            let destVC = segue.destinationController as! ExportImportViewController
            destVC.preferenceViewController = self
            destVC.mode = .Import
        default:
            break
        }
    }

    func preferenceChanged(sender: Any?) {
        loadPreference()
        self.tableView.reloadData()
    }
}
