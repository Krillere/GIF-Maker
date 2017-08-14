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

    // Undo / Redo menu items
    @IBOutlet var undoMenuItem:NSMenuItem!
    @IBOutlet var redoMenuItem:NSMenuItem!
    
    @IBOutlet var eraserMenuItem:NSMenuItem!
    @IBOutlet var eyedropperMenuItem:NSMenuItem!
    
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

    
    // MARK: Pro
    func createPurchaseMenuItem() {
        guard let menu = NSApplication.shared().mainMenu else { return }
        let newItem = NSMenuItem(title: "UnlockPro", action: nil, keyEquivalent: "")
        let newMenu = NSMenu(title: "Unlock Pro")
        
        let unlockItem = NSMenuItem(title: "Unlock Pro", action: #selector(AppDelegate.unlockProButtonClicked), keyEquivalent: "")
        let unlockedItem = NSMenuItem(title: "Previously unlocked Pro", action: #selector(AppDelegate.unlockedButtonClicked), keyEquivalent: "")
        
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
            createPurchaseMenuItem()
        }
    }
}

