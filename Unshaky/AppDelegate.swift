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

    @IBOutlet weak var menu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    @IBOutlet weak var window: NSWindow!
    private var shakyPressPreventer : ShakyPressPreventer
    @IBOutlet weak var dismissShakyPressCountMenuItem: NSMenuItem!
    @IBOutlet weak var preferenceMenuItem: NSMenuItem!
    @IBOutlet weak var versionMenuItem: NSMenuItem!
    @IBOutlet weak var isEnabledMenuItem: NSMenuItem!
    
    override init() {
        shakyPressPreventer = ShakyPressPreventer.sharedInstance()
        super.init()
    }

    @objc func updateStatLabel() {
        dismissShakyPressCountMenuItem.title = "☚ \(Counter.shared.statString)..."
    }

    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

    @objc func updateEnabledLabel() {
        isEnabledMenuItem.title = ShakyPressPreventer.sharedInstance().isDisabled()
            ? NSLocalizedString("💤 Unshaky is disabled, click to enable", comment: "")
            : NSLocalizedString("🧹 Unshaky is enabled, click to disable", comment: "");
    }

    @IBAction func enabledClicked(_ sender: Any) {
        ShakyPressPreventer.sharedInstance()?.setDisabled(
            !ShakyPressPreventer.sharedInstance().isDisabled()
        );
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let icon = NSImage(named: "UnshakyTemplate")
        statusItem.image = icon
        
        statusItem.menu = menu
        statusItem.behavior = .removalAllowed
        statusItem.menu?.delegate = self

        updateStatLabel()
        updateEnabledLabel()

        // show version number
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        versionMenuItem.title = String(format: NSLocalizedString("Version", comment: ""), version)

        shakyPressPreventer.setStatisticsHandler { (keyCode: Int32) in
            Counter.shared.increment(keyCode: keyCode)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(updateStatLabel), name: .counterUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateEnabledLabel), name: .enabledToggled, object: nil)

        setup()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        shakyPressPreventer.removeEventTap()
        NotificationCenter.default.removeObserver(self)
        Counter.shared.save()
    }

    // applicationDidBecomeActive is only called if Unshaky is opened
    // again when it is already running. So I can make the status bar item
    // show up again here.
    func applicationDidBecomeActive(_ notification: Notification) {
        statusItem.isVisible = true
    }

    //
    // Basic
    //
    func setup() {
        // this following lines will add Unshaky.app to privacy->accessibility panel, unchecked
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let accessEnabled = AXIsProcessTrustedWithOptions([checkOptPrompt: false] as CFDictionary?)

        if (!shakyPressPreventer.setupEventTap() || !accessEnabled) {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Accessibility Help", comment: "")
            alert.runModal()
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            NSApplication.shared.terminate(self)
        }
    }

    func recover() {
        shakyPressPreventer.removeEventTap()
        setup()
    }

    func checkAndRecoverIfNeeded() {
        if !shakyPressPreventer.eventTapEnabled() {
            print("Event tap is not enable, try to recover.")
            recover()
        }
    }
    
    //
    // DEBUG Function
    //
    var debugWindowController: NSWindowController!
    var debugWindow: NSWindow!
    @IBAction func debugClicked(_ sender: Any) {
        // we use shakyPressPreventer.debugViewController == nil to track
        // whether a debug window is already open
        // so when the window is closed, we will
        // update shakyPressPreventer.debugViewController to nil
        if (shakyPressPreventer.debugViewController != nil) {
            return;
        }

        let windowStyleMaskRawValue = NSWindow.StyleMask.closable.rawValue | NSWindow.StyleMask.titled.rawValue | NSWindow.StyleMask.resizable.rawValue
        let windowFrame = NSMakeRect(100, 100, 600, 400)
        debugWindow = NSWindow(contentRect: windowFrame, styleMask: .init(rawValue: windowStyleMaskRawValue), backing: .buffered, defer: false)
        debugWindowController = NSWindowController(window: debugWindow)
        debugWindow.delegate = self

        let debugPanelStoryboard = NSStoryboard(name: "Debug", bundle: nil)
        let debugViewController = (debugPanelStoryboard.instantiateController(withIdentifier: "Debug") as! DebugViewController)

        debugWindow.contentView = debugViewController.view
        debugWindow.orderFrontRegardless()
        shakyPressPreventer.debugViewController = debugViewController
    }
    
    //
    // Preference
    //
    var preferenceWindowController: NSWindowController!
    @IBAction func preferenceClicked(_ sender: Any) {
        // prevent multiple preference windows
        for window in NSApplication.shared.windows {
            if window.title == NSLocalizedString("Configuration Window Title", comment: "") && window.isVisible {
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        let preferencePanelStoryboard = NSStoryboard(name: "Preference", bundle: nil)
        preferenceWindowController = (preferencePanelStoryboard.instantiateController(withIdentifier: "Preference") as! NSWindowController)
        preferenceWindowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    //
    // Counter
    //
    var counterWindowController: NSWindowController!
    @IBAction func statClicked(_ sender: Any) {
        let counterPanelStoryboard = NSStoryboard(name: "Counter", bundle: nil)
        counterWindowController = (counterPanelStoryboard.instantiateController(withIdentifier: "Counter") as! NSWindowController)
        counterWindowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: NSWindowDelegate {
    // update shakyPressPreventer.debugViewController to nil
    // when debug window is closed
    func windowWillClose(_ notification: Notification) {
        shakyPressPreventer.debugViewController = nil
        debugWindowController = nil
        debugWindow = nil
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        checkAndRecoverIfNeeded()
    }
}

extension Notification.Name {
    static let enabledToggled = Notification.Name("enabled-toggled")
}
