//
//  ViewController.swift
//  GIF
//
//  Created by Christian Lundtofte on 14/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa
import StoreKit

class ViewController: NSViewController {
    // MARK: Fields
    
    // Constants
    static let backgroundColor = NSColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 1.0)
    
    // TODO: Create a delegate or something instead of this mess
    static let editingEndedNotificationName = NSNotification.Name(rawValue: "EditingEnded")
    static let loadedDocumentFramesNotificationName = NSNotification.Name(rawValue: "DocumentFrames")
    
    // UI elements
    @IBOutlet var imageCollectionView:NSCollectionView!
    @IBOutlet var frameDurationTextField:NSTextField!
    @IBOutlet var FPSLabel:NSTextField!
    @IBOutlet var addFrameButton:NSButton!
    @IBOutlet var loopsTextField:NSTextField!
    
    // Fields used in UI handling
    var currentFrames:[GIFFrame] = [GIFFrame.emptyFrame] // Default is 1 empty image, to show something in UI
    var selectedRow:IndexPath? = nil // Needed for inserting and removing item
    var indexPathsOfItemsBeingDragged: Set<IndexPath>! // Paths of items being dragged (If dragging inside the app)
    var editingWindowController:NSWindowController?
    
    // Preview variables
    var previewImages:[NSImage] = []
    var previewLoops:Int = GIFHandler.defaultLoops
    var previewFrameDuration:Double = GIFHandler.defaultFrameDuration

    
    // MARK: View setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Close color panel if open.
        if NSColorPanel.sharedColorPanelExists() {
            let panel = NSColorPanel.shared()
            panel.close()
        }
        
        configureCollectionView()
        setupNotificationListeners()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.backgroundColor = ViewController.backgroundColor

        // Sets up window border
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.isMovableByWindowBackground = true
        self.view.window?.titleVisibility = NSWindowTitleVisibility.hidden
        self.view.window?.backgroundColor = ViewController.backgroundColor
        
        self.imageCollectionView.backgroundView?.backgroundColor = ViewController.backgroundColor
        self.imageCollectionView.backgroundColor = ViewController.backgroundColor
        
        frameDurationTextField.wantsLayer = true
        frameDurationTextField.layer?.cornerRadius = 3
        
        addFrameButton.becomeFirstResponder()
        
        // Do we already have menu items?
        if let menu = NSApplication.shared().menu {
            if menu.item(withTitle: "Actions") == nil {
                self.setupMenuItems()
            }
        }
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }
    
    // View changing
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPreview" {
            if let viewController = segue.destinationController as? PreviewViewController {
                let previewImg = GIFHandler.createGIF(with: previewImages, loops: previewLoops, secondsPrFrame: previewFrameDuration)
                viewController.previewImage = previewImg
            }
        }
    }

    
    // MARK: UI
    override func controlTextDidChange(_ obj: Notification) {
        if let field = obj.object as? NSTextField {
            
            if field == frameDurationTextField { // Frame duration changed
                reloadFPS()
            }
        }

    }
    
    func reloadFPS() {
        let val = frameDurationTextField.stringValue
        if let fVal = Float(val) { // Validate field
            if fVal < 0 {
                showError("Frame duration must be a positive number.")
                return
            }
            
            // Find FPS
            let fps = round(1/fVal)
            FPSLabel.stringValue = String(format: "seconds (%.0lf FPS)", fps)
        }
        else {
            showError("Frame duration must be a positive number.")
        }
    }
    
    func reloadImages() {
        imageCollectionView.reloadData()
    }
    
    func setupMenuItems() {
        guard let menu = NSApplication.shared().mainMenu else { return }
        let newItem = NSMenuItem(title: "Actions", action: nil, keyEquivalent: "")
        let newMenu = NSMenu(title: "Actions")
        
        /*
         Import .GIF
         Export .GIF
         -
         Add frame
         -
         Preview
         Edit
         Reset
        */
        
        let importItem = NSMenuItem(title: "Import .GIF", action: #selector(ViewController.loadGIFButtonClicked(sender:)), keyEquivalent: "")
        importItem.keyEquivalentModifierMask = .command
        importItem.keyEquivalent = "o"
        
        let exportItem = NSMenuItem(title: "Export .GIF", action: #selector(ViewController.exportGIFButtonClicked(sender:)), keyEquivalent: "")
        exportItem.keyEquivalentModifierMask = .command
        exportItem.keyEquivalent = "s"
        
        let addFrameItem = NSMenuItem(title: "Add frame", action: #selector(ViewController.addFrameButtonClicked(sender:)), keyEquivalent: "")
        addFrameItem.keyEquivalent = "f"
        addFrameItem.keyEquivalentModifierMask = .command
        
        let previewItem = NSMenuItem(title: "Preview", action: #selector(ViewController.previewButtonClicked(sender:)), keyEquivalent: "")
        previewItem.keyEquivalentModifierMask = .command
        previewItem.keyEquivalent = "p"
        
        let editItem = NSMenuItem(title: "Edit", action: #selector(ViewController.editButtonClicked(sender:)), keyEquivalent: "")
        editItem.keyEquivalentModifierMask = .command
        editItem.keyEquivalent = "e"
        
        let resetItem = NSMenuItem(title: "Reset", action: #selector(ViewController.resetButtonClicked(sender:)), keyEquivalent: "")
        resetItem.keyEquivalent = "r"
        resetItem.keyEquivalentModifierMask = .command
        
        newMenu.addItem(importItem)
        newMenu.addItem(exportItem)
        newMenu.addItem(NSMenuItem.separator())
        newMenu.addItem(addFrameItem)
        newMenu.addItem(NSMenuItem.separator())
        newMenu.addItem(previewItem)
        newMenu.addItem(editItem)
        newMenu.addItem(resetItem)
        
        newItem.submenu = newMenu
        menu.insertItem(newItem, at: 1)
    }
    
    // MARK: Buttons
    // Adds a new frame
    @IBAction func addFrameButtonClicked(sender: AnyObject?) {
        if let indexPath = selectedRow { // Add after selectedRow
            currentFrames.insert(GIFFrame.emptyFrame, at: indexPath.item+1)
            selectedRow = IndexPath(item: indexPath.item+1, section: 0)
        }
        else { // Add empty frame
            currentFrames.append(GIFFrame.emptyFrame)
        }

        self.imageCollectionView.reloadData()
    }
    
    // Edit button clicked
    @IBAction func editButtonClicked(sender: AnyObject?) {
        var startIndex:Int? = nil
        
        if let indexPath = imageCollectionView.selectionIndexPaths.first {
            startIndex = indexPath.item
        }
        
        showEditing(withIndex: startIndex)
    }
    
    // Export a gif
    @IBAction func exportGIFButtonClicked(sender: AnyObject?) {
        let validate = self.validateAndFindGIFValues()
        
        if validate.error {
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["gif"]
        panel.begin { (res) in
            if res == NSFileHandlingPanelOKButton {
                if let url = panel.url {
                    GIFHandler.createAndSaveGIF(with: validate.images, savePath: url, loops: validate.loops, secondsPrFrame: validate.frameDuration)
                    NSWorkspace.shared().activateFileViewerSelecting([url])
                }
            }
        }
        
    }
    
    // Load a gif from a file
    @IBAction func loadGIFButtonClicked(sender: AnyObject?) {
        // Show file panel
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["gif"]
        panel.allowsMultipleSelection = false
        panel.allowsOtherFileTypes = false
        panel.canChooseDirectories = false
        panel.begin { (res) in
            if res == NSFileHandlingPanelOKButton {
                // Load image from file
                if let url = panel.url {
                    self.importGIF(from: url)
                }
            }
        }
    }
    
    // Reset everything
    @IBAction func resetButtonClicked(sender: AnyObject?) {
        let alert = FancyAlert()
        alert.alertStyle = .warning
        alert.informativeText = "This will remove everything, are you sure?"
        alert.messageText = "Are you sure?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        alert.beginSheetModal(for: self.view.window!) { (resp) in
            if resp == NSAlertFirstButtonReturn { // Yes clicked, reset
                self.currentFrames = [GIFFrame.emptyFrame]
                self.frameDurationTextField.stringValue = String(GIFHandler.defaultFrameDuration)
                self.loopsTextField.stringValue = String(GIFHandler.defaultLoops)
                self.imageCollectionView.reloadData()
                self.deselectAll()
            }
        }
    }
    
    // Preview
    @IBAction func previewButtonClicked(sender: AnyObject?) {
        let validate = self.validateAndFindGIFValues()
        
        if validate.error {
            return
        }
        
        self.previewLoops = validate.loops
        self.previewFrameDuration = validate.frameDuration
        self.previewImages = validate.images
        
        self.performSegue(withIdentifier: "ShowPreview", sender: self)
    }
    
    
    // MARK: Helpers
    // Validates values from UI and returns them
    func validateAndFindGIFValues() -> (error: Bool, loops: Int, frameDuration: Double, images: [NSImage]) {
        let emp:[NSImage] = []
        let errorReturn = (error: true, loops: GIFHandler.defaultLoops, frameDuration: GIFHandler.defaultFrameDuration, images: emp)
        
        guard let loops = Int(loopsTextField.stringValue) else {
            showError("Invalid value for loop count.")
            return errorReturn
        }
        guard let frameDuration = Double(frameDurationTextField.stringValue) else {
            showError("Invalid value for frame duration.")
            return errorReturn
        }
        if frameDuration < 0.0 {
            showError("Frame duration must be a positive number.")
            return errorReturn
        }
        
        // Remove empty images
        var tmpImages:[NSImage] = []
        for frame in currentFrames {
            if let img = frame.image {
                tmpImages.append(img)
            }
        }
        
        if tmpImages.count == 0 {
            showError("No frames in gif")
            return errorReturn
        }
        
        // Success!
        return (error: false, loops: loops, frameDuration: frameDuration, images: tmpImages)
    }
    
    // Imports a gif from a given location
    func importGIF(from: URL) {
        if let image = NSImage(contentsOf: from) {
            // Set values from the .GIF
            let newValues = GIFHandler.loadGIF(with: image)
            
            self.currentFrames = newValues.frames
            self.frameDurationTextField.stringValue = String(newValues.frameDuration)
            self.loopsTextField.stringValue = String(newValues.loops)
            
            self.selectedRow = nil
            self.imageCollectionView.reloadData()
            reloadFPS()
        }
    }
    
    // Adds NotificationCenter listeners
    func setupNotificationListeners() {
        // Listeners for events regarding frames and images
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reloadImages),
                                               name: ViewController.editingEndedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.documentFramesLoaded(notification:)),
                                               name: ViewController.loadedDocumentFramesNotificationName, object: nil)
        
        // GIFHandler events
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.gifError(sender:)),
                                               name: GIFHandler.errorNotificationName, object: nil)
    }
    
    // Frames loaded using 'Open with...' menu
    func documentFramesLoaded(notification: NSNotification) {
        if let values = notification.userInfo?["info"] as? GIFRepresentation {
            self.currentFrames = values.frames
            self.frameDurationTextField.stringValue = String(values.frameDuration)
            self.loopsTextField.stringValue = String(values.loops)
            
            self.selectedRow = nil
            self.imageCollectionView.reloadData()
            
            reloadFPS()
        }
    }
    
    // Shows editing window with given start
    func showEditing(withIndex: Int? = nil) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        editingWindowController = storyboard.instantiateController(withIdentifier: "EditingWindow") as? NSWindowController
        
        if let contentViewController = editingWindowController?.contentViewController as? EditViewController {
            contentViewController.setFrames(frames: self.currentFrames)
            contentViewController.initialFrameNumber = withIndex
        }
        
        editingWindowController?.showWindow(self)
    }

    // Notification when an error occurs in GIFHandler
    func gifError(sender: NSNotification) {
        guard let userInfo = sender.userInfo,
              let error = userInfo["Error"] as? String else {
            return
        }
        
        showError(error)
    }
    
    // Shows an error
    func showError(_ error: String) {
        let alert = FancyAlert()
        alert.messageText = "An error occurred"
        alert.informativeText = error
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
}
