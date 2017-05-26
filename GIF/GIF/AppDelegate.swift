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


    // MARK: Setup
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    
    // MARK: Menu items
    @IBAction func menuItemLoad(sender: AnyObject?) {
        NotificationCenter.default.post(name: ViewController.menuItemImportNotificationName, object: nil)
    }
    
    @IBAction func menuItemExport(sender: AnyObject?) {
        NotificationCenter.default.post(name: ViewController.menuItemExportNotificationName, object: nil)
    }

    @IBAction func menuItemAddFrame(sender: AnyObject?) {
        NotificationCenter.default.post(name: ViewController.menuItemAddFrameNotificationName, object: nil)
    }
    
    @IBAction func menuItemReset(sender: AnyObject?) {
        NotificationCenter.default.post(name: ViewController.menuItemResetNotificationName, object: nil)
    }
    
    @IBAction func menuItemPreview(sender: AnyObject?) {
        NotificationCenter.default.post(name: ViewController.menuItemPreviewNotificationName, object: nil)
    }
    
    @IBAction func menuItemEdit(sender: AnyObject?) {
        NotificationCenter.default.post(name: ViewController.menuItemEditNotificationName, object: nil)
    }
}

