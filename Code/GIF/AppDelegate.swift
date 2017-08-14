//
//  AppDelegate.swift
//  GIF
//
//  Created by Christian Lundtofte on 14/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa
import StoreKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Constants (Menu items)
    static let menuItemImportNotificationName = NSNotification.Name(rawValue: "MenuItemImport")
    static let menuItemExportNotificationName = NSNotification.Name(rawValue: "MenuItemExport")
    static let menuItemAddFrameNotificationName = NSNotification.Name(rawValue: "MenuItemAddFrame")
    static let menuItemPreviewNotificationName = NSNotification.Name(rawValue: "MenuItemPreview")
    static let menuItemResetNotificationName = NSNotification.Name(rawValue: "MenuItemReset")
    static let menuItemEditNotificationName = NSNotification.Name(rawValue: "MenuItemEdit")
    
    
    // iAP
    var products = [SKProduct]()

    // MARK: Setup
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.productsLoaded),
                                               name: IAPHelper.IAPLoadedNotificationName,
                                               object: nil)
        
//        reloadProducts()
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
//        guard let menu = NSApplication.shared().mainMenu else { return }
//        let newItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
//        let newMenu = NSMenu(title: "Pro")
//        
//        newItem.submenu = newMenu
//        menu.insertItem(newItem, at: menu.items.count-1)
    }
    
    func doLiteMenuItem() {
        guard let menu = NSApplication.shared().mainMenu else { return }
        let newItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let newMenu = NSMenu(title: "Unlock Pro")
        
        let unlockItem = NSMenuItem(title: "Unlock Pro", action: #selector(AppDelegate.unlockProButtonClicked), keyEquivalent: "")
        let unlockedItem = NSMenuItem(title: "I previously unlocked Pro", action: #selector(AppDelegate.unlockedButtonClicked), keyEquivalent: "")
        
        newMenu.addItem(unlockItem)
        newMenu.addItem(unlockedItem)
        
        newItem.submenu = newMenu
        menu.insertItem(newItem, at: menu.items.count-1)
    }
    
    // Unlock button clicked
    func unlockProButtonClicked() {
        Products.store.buyProduct(products[0])
    }
    
    // Previously unlocked button clicked
    func unlockedButtonClicked() {
        if let window = NSApplication.shared().keyWindow {
            let alert = FancyAlert()
            alert.messageText = "Unlocking.."
            alert.informativeText = "Attempting to unlock.."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: window, completionHandler: nil)
        }
        
        Products.store.restorePurchases()
    }
    
    
    
    // MARK: In app purchase
    func reloadProducts() {
        products = []
        Products.store.requestProducts{success, products in
            if success {
                self.products = products!
            }
        }
    }
    
    func productsLoaded() {
        if !Products.store.isProductPurchased(Products.Pro) {
            self.doLiteMenuItem()
        }
        else {
            
        }
    }
}

