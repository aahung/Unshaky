//
//  PreferenceViewController.swift
//  Unshaky
//
//  Created by Xinhong LIU on 2018-07-10.
//  Copyright © 2018 Nested Error. All rights reserved.
//

import Cocoa

class PreferenceViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var keyboardLayoutsSelect: NSPopUpButton!
    @IBOutlet weak var delayAllTextField: NSTextField!

    let preference = Preference()

    override func viewDidLoad() {
        loadKeyloadLayouts()
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = NSLocalizedString("Configuration Window Title", comment: "")
    }

    func loadKeyloadLayouts() {
        keyboardLayoutsSelect.removeAllItems()
        keyboardLayoutsSelect.addItems(withTitles: KeyboardLayouts.availableKeyboardLayouts());
        keyboardLayoutsSelect.selectItem(withTitle: preference.keyboardLayout)
    }

    // used by delayEdited(:)
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
        self.tableView.reloadData()
    }
}

// IBActions
extension PreferenceViewController {

    @IBAction func delayEdited(_ sender: NSTextField) {
        let row = tableView.selectedRow
        guard let delayValue = Int(sender.stringValue) else {
            alertInvalidValue(invalidValue: sender.stringValue)
            return
        }
        preference.setDelay(delay: delayValue, code: preference.keyCodes[row])
    }

    @IBAction func enabledEdited(_ sender: NSButton) {
        let row = tableView.row(for: sender)
        let enabledValue = Bool(sender.state == .on)
        preference.setEnabled(enabled: enabledValue, code: preference.keyCodes[row])
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
        guard let keyboardLayout = keyboardLayoutsSelect.selectedItem?.title else {
            return
        }
        preference.setKeyboardLayout(keyboardLayout: keyboardLayout)
        tableView.reloadData()
    }

    @IBAction func setAllDelays(_ sender: Any) {
        guard let delay = Int(delayAllTextField.stringValue) else {
            alertInvalidValue(invalidValue: delayAllTextField.stringValue)
            return
        }
        preference.setDelayforAll(delay: delay)
        self.tableView.reloadData()
    }

    @IBAction func statisticsToggled(_ sender: Any) {
        ShakyPressPreventer.sharedInstance()?.loadStatisticsDisabled()
    }
}

// TableView
extension PreferenceViewController: NSTableViewDataSource, NSTableViewDelegate {
    // MARK: NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return preference.keyCodes.count
    }

    // MARK: NSTableViewDelegate
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if (tableColumn?.identifier)!.rawValue == "enabled" {
            return preference.enableds[preference.keyCodes[row]]
        }
        if (tableColumn?.identifier)!.rawValue == "key" {
            guard let keyString = KeyboardLayouts.shared().keyCodeToString()[NSNumber(
                value: preference.keyCodes[row])] else {
                    return "UNDEFINED KEY"
            }
            return keyString
        }
        if (tableColumn?.identifier)!.rawValue == "delay" {
            return preference.delays[preference.keyCodes[row]]
        }
        return nil
    }
}
