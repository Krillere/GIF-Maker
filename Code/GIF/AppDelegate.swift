//
//  AppDelegate.swift
//  GIF
//
//  Created by Christian Lundtofte on 14/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    static let menuItemImportNotificationName = NSNotification.Name(rawValue: "MenuItemImport")
    static let menuItemExportNotificationName = NSNotification.Name(rawValue: "MenuItemExport")
    static let menuItemAddFrameNotificationName = NSNotification.Name(rawValue: "MenuItemAddFrame")
    static let menuItemPreviewNotificationName = NSNotification.Name(rawValue: "MenuItemPreview")
    static let menuItemResetNotificationName = NSNotification.Name(rawValue: "MenuItemReset")
    static let menuItemEditNotificationName = NSNotification.Name(rawValue: "MenuItemEdit")
    

    // MARK: Setup
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        
        //doProMenuItem()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: Menu items
    @IBAction func menuItemLoad(sender: AnyObject?) {
        NotificationCenter.default.post(name: AppDelegate.menuItemImportNotificationName, object: nil)
    }
    
    @IBAction func menuItemExport(sender: AnyObject?) {
        NotificationCenter.default.post(name: AppDelegate.menuItemExportNotificationName, object: nil)
    }

    @IBAction func menuItemAddFrame(sender: AnyObject?) {
        NotificationCenter.default.post(name: AppDelegate.menuItemAddFrameNotificationName, object: nil)
    }
    
    @IBAction func menuItemReset(sender: AnyObject?) {
        NotificationCenter.default.post(name: AppDelegate.menuItemResetNotificationName, object: nil)
    }
    
    @IBAction func menuItemPreview(sender: AnyObject?) {
        NotificationCenter.default.post(name: AppDelegate.menuItemPreviewNotificationName, object: nil)
    }
    
    @IBAction func menuItemEdit(sender: AnyObject?) {
        NotificationCenter.default.post(name: AppDelegate.menuItemEditNotificationName, object: nil)
    }
    
    // MARK: Pro stuff
    func doProMenuItem() {
        
    }
    
    func doLiteMenuItem() {
        guard let menu = NSApplication.shared().mainMenu else { return }
        let newItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let newMenu = NSMenu(title: "Pro")
        
        
        newItem.submenu = newMenu
        menu.addItem(newItem)
    }
}

