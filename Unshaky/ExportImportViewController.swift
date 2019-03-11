//
//  ExportImportViewController.swift
//  Unshaky
//
//  Created by Xinhong LIU on 10/26/18.
//  Copyright © 2018 Nested Error. All rights reserved.
//

import Cocoa

class ExportImportViewController: NSViewController {

    enum Mode {
        case Export
        case Import
    }

    struct Configuration: Codable {
        let delays: [Int]
    }

    @IBOutlet weak var importButtons: NSStackView!
    @IBOutlet weak var exportButtons: NSStackView!
    @IBOutlet var textView: NSTextView!
    weak var preferenceViewController: PreferenceViewController?
    
    var mode: Mode!

    override func viewDidLoad() {
        super.viewDidLoad()

        switch mode {
        case .Export?:
            importButtons.isHidden = true
            loadPreference()
        case .Import?:
            exportButtons.isHidden = true
            textView.string = NSLocalizedString("Paste the configuration here", comment: "")
            textView.selectAll(textView)
        case .none:
            break
        }
    }

    func loadPreference() {
        let delays = UserDefaults.standard.array(forKey: "delays") as! [Int]
        let config = Configuration(delays: delays)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try! encoder.encode(config)
        let jsonString = String(data: jsonData, encoding: .utf8)
        textView.string = jsonString!
    }

    @IBAction func copyConfig(_ sender: Any) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textView.string, forType: .string)
        self.dismiss(self)
    }

    @IBAction func pasteConfig(_ sender: Any) {
        guard let jsonString = NSPasteboard.general.string(forType: .string) else {
            return
        }
        textView.string = jsonString
    }

    @IBAction func applyConfig(_ sender: Any) {
        guard let config = try? JSONDecoder().decode(Configuration.self, from: textView.string.data(using: .utf8)!) else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Invalid inputs", comment: "")
            alert.runModal()
            return
        }

        // validate length
        guard config.delays.count == Int(N_VIRTUAL_KEY) else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Invalid inputs, length does not match", comment: "")
            alert.runModal()
            return
        }

        UserDefaults.standard.set(config.delays, forKey: "delays")
        preferenceViewController?.preferenceChanged(sender: self)
        self.dismiss(self)
    }
}
