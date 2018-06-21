//
//  AppDelegate.swift
//  Unshaky
//
//  Created by Xinhong LIU on 2018-06-21.
//  Copyright © 2018 Nested Error. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let defaults = UserDefaults.standard
    @IBOutlet weak var menu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    @IBOutlet weak var window: NSWindow!
    private var shakyPressPreventer : ShakyPressPreventer
    @IBOutlet weak var dismissShakyPressCountMenuItem: NSMenuItem!
    
    private var dismissCount = 0
    
    override init() {
        shakyPressPreventer = ShakyPressPreventer()
        super.init()
        if (!shakyPressPreventer.setupInputDeviceListener()) {
            let alert = NSAlert()
            alert.messageText = "You have to go to: System Preferences -> Security & Privacy -> Privacy (Tab) -> Accessibility (Left panel) and then add the Unshaky.app."
            alert.runModal()
            NSApplication.shared.terminate(self)
        }
        shakyPressPreventer.shakyPressDismissed {
            self.dismissCount += 1
            OperationQueue.main.addOperation {
                self.updateDismissCountLabel()
            }
        }
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    func updateDismissCountLabel() {
        dismissShakyPressCountMenuItem.title = "Dismiss shaky key \(dismissCount) times"
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let launcherAppId = "com.nestederror.UnshakyLaunchHelper"
        SMLoginItemSetEnabled(launcherAppId as CFString, true)
        
        let icon = NSImage(named: NSImage.Name(rawValue: "UnshakyTemplate"))
        statusItem.image = icon
        
        statusItem.menu = menu
        
        dismissCount = defaults.integer(forKey: "DISMISS_COUNT")
        updateDismissCountLabel()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        defaults.set(dismissCount, forKey: "DISMISS_COUNT")
        defaults.synchronize()
    }
}
