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
    @IBOutlet weak var keyboardLayoutsSelect: NSPopUpButton!

    let defaults = UserDefaults.standard
    var delays: [Int]!
    var keyCodes: [Int]!
    let nVirtualKey = Int(N_VIRTUAL_KEY)
    
    override func viewDidLoad() {
        keyboardLayoutsSelect.removeAllItems()
        keyboardLayoutsSelect.addItems(withTitles: KeyboardLayouts.availableKeyboardLayouts());

        loadPreference()
        super.viewDidLoad()

        keyCodes = Array(0..<nVirtualKey).filter({ (i) -> Bool in
            return KeyboardLayouts.shared().keyCodeToString()[NSNumber(value: i)] != nil
        }).sorted { (a, b) -> Bool in
            return KeyboardLayouts.shared().keyCodeToString()[NSNumber(value: a)]! < KeyboardLayouts.shared().keyCodeToString()[NSNumber(value: b)]!
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = NSLocalizedString("Configuration Window Title", comment: "")
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
            guard let keyString = KeyboardLayouts.shared().keyCodeToString()[NSNumber(value: keyCodes[row])] else {
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

    @IBAction func ignoreInternalKeyboardToggled(_ sender: Any) {
        ShakyPressPreventer.sharedInstance()?.loadIgnoreInternalKeyboard()
    }

    @IBAction func workaroundForCmdSpaceToggled(_ sender: Any) {
        ShakyPressPreventer.sharedInstance()?.loadWorkaroundForCmdSpace()
    }

    @IBAction func aggressiveModeToggled(_ sender: Any) {
        ShakyPressPreventer.sharedInstance()?.loadAggressiveMode()
    }

    @IBAction func agressiveModeHelpPressed(_ sender: Any) {
        if let url = URL(string: "https://github.com/aahung/Unshaky/wiki/Aggressive-mode") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func keyboardLayoutChanged(_ sender: Any) {
        guard let selectedTitle = keyboardLayoutsSelect.selectedItem?.title else {
            return
        }
        KeyboardLayouts.shared().setKeyboardLayout(selectedTitle)
        tableView.reloadData()
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
        alert.messageText = String(format: NSLocalizedString("Invalid Delay", comment: ""), invalidValue)
        alert.runModal()
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "export":
            let destVC = segue.destinationController as! ExportImportViewController
            destVC.preferenceViewController = self
            destVC.mode = .Export
        case "import":
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
