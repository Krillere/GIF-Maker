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
    
    // IAP
    var products = [SKProduct]()
    

    // MARK: Setup
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // In app purchase setup
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.productsLoaded),
                                               name: IAPHelper.IAPLoadedNotificationName,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.handlePurchaseNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.failedPurchase),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPPurchaseFailed),
                                               object: nil)
        loadProducts()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    
    // MARK: Pro / watermark removal
    // Should this really be in AppDelegate?
    func createPurchaseMenu() {
        guard let menu = NSApplication.shared().mainMenu else { return }
        let newItem = NSMenuItem(title: "UnlockPro", action: nil, keyEquivalent: "")
        let newMenu = NSMenu(title: "Remove watermarks")
        
        let unlockItem = NSMenuItem(title: "Remove watermarks", action: #selector(AppDelegate.unlockProButtonClicked), keyEquivalent: "")
        let unlockedItem = NSMenuItem(title: "Previously purchased", action: #selector(AppDelegate.unlockedButtonClicked), keyEquivalent: "")
        
        newMenu.addItem(unlockItem)
        newMenu.addItem(unlockedItem)
        
        newItem.submenu = newMenu
        menu.insertItem(newItem, at: menu.items.count-1)
    }
    
    func removePurchaseMenu() {
        guard let menu = NSApplication.shared().mainMenu,
            let item = menu.item(withTitle: "UnlockPro") else { return }
        menu.removeItem(item)
    }
    
    // Unlock button clicked
    func unlockProButtonClicked() {
        Products.store.buyProduct(products[0])
    }
    
    // Previously unlocked button clicked
    func unlockedButtonClicked() {
        
        let alert = FancyAlert()
        alert.messageText = "Unlocking.."
        alert.informativeText = "Attempting to unlock. This might take a while."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        
        if let window = NSApplication.shared().mainWindow {
            alert.beginSheetModal(for: window, completionHandler: nil)
        }
        else {
            alert.runModal()
        }
        
        Products.store.restorePurchases()
    }

    
    // MARK: In app purchase
    func loadProducts() {
        products = []
        Products.store.requestProducts{success, products in
            if success {
                self.products = products!
            }
        }
    }
    
    func productsLoaded() {
        if !Products.store.isProductPurchased(Products.Pro) {
            createPurchaseMenu()
        }
    }
    
    // Purchase did not succeed
    func failedPurchase() {
        
        if !Products.store.isProductPurchased(Products.Pro) {
            let alert = FancyAlert()
            alert.messageText = "An error occurred"
            alert.informativeText = "An error occurred during purchase. If you are trying to restore the purchase, make sure that you purchased it previously."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            
            if let window = NSApplication.shared().mainWindow {
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
            else {
                alert.runModal()
            }
        }
    }
    
    func handlePurchaseNotification(_ notification: Notification) {
        
        if Products.store.isProductPurchased(Products.Pro) {
            removePurchaseMenu()
            
            let alert = FancyAlert()
            alert.messageText = "Watermarks removed"
            alert.informativeText = "Watermarks are now removed!"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            
            if let window = NSApplication.shared().mainWindow {
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
            else {
                alert.runModal()
            }
        }
        else { // Error
            let alert = FancyAlert()
            alert.messageText = "An error occurred"
            alert.informativeText = "An error occurred during purchase. If you are trying to restore the purchase, make sure that you purchased it previously."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            
            if let window = NSApplication.shared().mainWindow {
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
            else {
                alert.runModal()
            }
        }
    }
}

