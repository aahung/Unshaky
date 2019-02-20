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
    
    override func viewDidLoad() {
        loadPreference()
        super.viewDidLoad()
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

    // this list credits to the answer at https://stackoverflow.com/a/36901239/2361752
    let keyCodeToString = [29:     " 0",
                           18:     " 1",
                           19:     " 2",
                           20:     " 3",
                           21:     " 4",
                           23:     " 5",
                           22:     " 6",
                           26:     " 7",
                           28:     " 8",
                           25:     " 9",
                           0:      " A",
                           11:     " B",
                           8:      " C",
                           2:      " D",
                           14:     " E",
                           3:      " F",
                           5:      " G",
                           4:      " H",
                           34:     " I",
                           38:     " J",
                           40:     " K",
                           37:     " L",
                           46:     " M",
                           45:     " N",
                           31:     " O",
                           35:     " P",
                           12:     " Q",
                           15:     " R",
                           1:      " S",
                           17:     " T",
                           32:     " U",
                           9:      " V",
                           13:     " W",
                           7:      " X",
                           16:     " Y",
                           6:      " Z",
                           10:     "SectionSign",
                           50:     "Grave",
                           27:     "Minus",
                           24:     "Equal",
                           33:     "LeftBracket",
                           30:     "RightBracket",
                           41:     "Semicolon",
                           39:     "Quote",
                           43:     "Comma",
                           47:     "Period",
                           44:     "Slash",
                           42:     "Backslash",
                           82:     "Keypad0 0",
                           83:     "Keypad1 1",
                           84:     "Keypad2 2",
                           85:     "Keypad3 3",
                           86:     "Keypad4 4",
                           87:     "Keypad5 5",
                           88:     "Keypad6 6",
                           89:     "Keypad7 7",
                           91:     "Keypad8 8",
                           92:     "Keypad9 9",
                           65:     "KeypadDecimal",
                           67:     "KeypadMultiply",
                           69:     "KeypadPlus",
                           75:     "KeypadDivide",
                           78:     "KeypadMinus",
                           81:     "KeypadEquals",
                           71:     "KeypadClear",
                           76:     "KeypadEnter",
                           49:     "Space",
                           36:     "Return",
                           48:     "Tab",
                           51:     "Delete",
                           117:    "ForwardDelete",
                           52:     "Linefeed",
                           53:     "Escape",
                           57:     "CapsLock",
                           122:    "F1",
                           120:    "F2",
                           99:     "F3",
                           118:    "F4",
                           96:     "F5",
                           97:     "F6",
                           98:     "F7",
                           100:    "F8",
                           101:    "F9",
                           109:    "F10",
                           103:    "F11",
                           111:    "F12",
                           105:    "F13",
                           107:    "F14",
                           113:    "F15",
                           106:    "F16",
                           64:     "F17",
                           79:     "F18",
                           80:     "F19",
                           90:     "F20",
                           72:     "VolumeUp",
                           73:     "VolumeDown",
                           74:     "Mute",
                           114:    "Help/Insert",
                           115:    "Home",
                           119:    "End",
                           116:    "PageUp",
                           121:    "PageDown",
                           123:    "Arrow Left",
                           124:    "Arrow Right",
                           125:    "Arrow Down",
                           126:    "Arrow Up",
                           145:    "Brightness Down",
                           144:    "Brightness Up",
                           130:    "Dashboard",
                           131:    "LaunchPad"]
    
    
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
