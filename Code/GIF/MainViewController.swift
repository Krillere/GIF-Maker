//
//  MainViewController.swift
//  GIF
//
//  Created by Christian Lundtofte on 14/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    // MARK: Fields
    
    // Constants
    
    // TODO: Create a delegate or something instead of this mess
    static let editingEndedNotificationName = NSNotification.Name(rawValue: "EditingEnded")
    static let loadedDocumentFramesNotificationName = NSNotification.Name(rawValue: "DocumentFrames")
    
    // UI elements
    @IBOutlet var imageCollectionView:NSCollectionView!
    @IBOutlet var addFrameButton:NSButton!
    @IBOutlet var loopsTextField:NSTextField!
    @IBOutlet var loadingView:LoadingView!
    
    // Fields used in UI handling
    var currentFrames:[GIFFrame] = [GIFFrame.emptyFrame] // Default is 1 empty image, to show something in UI
    var selectedRow:IndexPath? = nil // Needed for inserting and removing item
    var indexPathsOfItemsBeingDragged: Set<IndexPath>! // Paths of items being dragged (If dragging inside the app)
    var editingWindowController:NSWindowController?
    
    // Preview variables
    var previewImage:NSImage?

    
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
        
        self.view.backgroundColor = Constants.darkBackgroundColor

        // Sets up window border
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.isMovableByWindowBackground = true
        self.view.window?.titleVisibility = NSWindowTitleVisibility.hidden
        self.view.window?.backgroundColor = Constants.darkBackgroundColor
        
        self.imageCollectionView.backgroundView?.backgroundColor = Constants.darkBackgroundColor
        self.imageCollectionView.backgroundColor = Constants.darkBackgroundColor
        
        addFrameButton.becomeFirstResponder()
        
        // If menu items does not exist, create them
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
            if let viewController = segue.destinationController as? PreviewViewController,
                let preview = self.previewImage {
                viewController.previewImage = preview
            }
        }
    }

    
    // MARK: UI
    override func controlTextDidChange(_ obj: Notification) {
        if let field = obj.object as? NSTextField {
            if field == loopsTextField {
                if let _ = Int(loopsTextField.stringValue) { }
                else {
                    showError("Loops must be an integer!")
                    loopsTextField.stringValue = "0"
                }
            }
        }

    }

    func reloadImages() {
        imageCollectionView.reloadData()
    }
    
    // Creates menu item
    func setupMenuItems() {
        guard let menu = NSApplication.shared().mainMenu else { return }
        let newItem = NSMenuItem(title: "Actions", action: nil, keyEquivalent: "")
        let newMenu = NSMenu(title: "Actions")
        
        /*
         Import .GIF (CMD+O)
         Export .GIF (CMD+S)
         -
         Add frame (CMD+F)
         Reverse frames
         Set all frame durations
         -
         Preview (CMD+P)
         Edit (CMD+E)
         Reset (CMD+R)
        */
        
        let importItem = NSMenuItem(title: "Import", action: #selector(MainViewController.importButtonClicked(sender:)), keyEquivalent: "")
        importItem.keyEquivalentModifierMask = .command
        importItem.keyEquivalent = "o"
        
        let exportItem = NSMenuItem(title: "Export .GIF", action: #selector(MainViewController.exportGIFButtonClicked(sender:)), keyEquivalent: "")
        exportItem.keyEquivalentModifierMask = .command
        exportItem.keyEquivalent = "s"
        
        let addFrameItem = NSMenuItem(title: "Add frame", action: #selector(MainViewController.addFrameButtonClicked(sender:)), keyEquivalent: "")
        addFrameItem.keyEquivalent = "f"
        addFrameItem.keyEquivalentModifierMask = .command
        
        let reverseItem = NSMenuItem(title: "Reverse frames", action: #selector(MainViewController.reverseFrames), keyEquivalent: "")
        let changeDuration = NSMenuItem(title: "Set all frame durations", action: #selector(MainViewController.setAllFrameDurations), keyEquivalent: "")
        
        let previewItem = NSMenuItem(title: "Preview", action: #selector(MainViewController.previewButtonClicked(sender:)), keyEquivalent: "")
        previewItem.keyEquivalentModifierMask = .command
        previewItem.keyEquivalent = "p"
        
        let editItem = NSMenuItem(title: "Edit", action: #selector(MainViewController.editButtonClicked(sender:)), keyEquivalent: "")
        editItem.keyEquivalentModifierMask = .command
        editItem.keyEquivalent = "e"
        
        let resetItem = NSMenuItem(title: "Reset", action: #selector(MainViewController.resetButtonClicked(sender:)), keyEquivalent: "")
        resetItem.keyEquivalent = "r"
        resetItem.keyEquivalentModifierMask = .command
        
        newMenu.addItem(importItem)
        newMenu.addItem(exportItem)
        newMenu.addItem(NSMenuItem.separator())
        newMenu.addItem(addFrameItem)
        newMenu.addItem(reverseItem)
        newMenu.addItem(changeDuration)
        newMenu.addItem(NSMenuItem.separator())
        newMenu.addItem(previewItem)
        newMenu.addItem(editItem)
        newMenu.addItem(resetItem)
        
        newItem.submenu = newMenu
        menu.insertItem(newItem, at: 1)
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
    
    // Shows informational alert
    func showAlert(title: String, msg: String) {
        let alert = FancyAlert()
        alert.messageText = title
        alert.informativeText = msg
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    // Shows import error
    func importError() {
        self.showError("Could not open file. It might be in a format that Smart GIF Maker does not understand.")
    }
    
    
    // MARK: Buttons
    // Adds a new frame
    @IBAction func addFrameButtonClicked(sender: AnyObject?) {
        if let indexPath = selectedRow { // Add after selectedRow
            let selectedFrame = self.currentFrames[indexPath.item]
            let newFrame = GIFFrame.emptyFrame
            newFrame.duration = selectedFrame.duration
            
            currentFrames.insert(newFrame, at: indexPath.item+1)
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
        let validate = self.findAndValidateUIValues()
        
        if validate.error {
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["gif"]
        panel.begin { (res) in
            if res == NSFileHandlingPanelOKButton {
                if let url = panel.url {
                    let rep = validate.gif
                    self.exportGIF(to: url, gif: rep)
                }
            }
        }
        
    }
    
    // Load a gif from a file
    @IBAction func importButtonClicked(sender: AnyObject?) {
        
        // Show file panel
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["gif", "mp4", "mov"]
        panel.allowsMultipleSelection = false
        panel.allowsOtherFileTypes = false
        panel.canChooseDirectories = false
        panel.begin { (res) in
            if res == NSFileHandlingPanelOKButton {
                // Load image from file
                if let url = panel.url {
                    let fileExtension = url.pathExtension
                    
                    if fileExtension == "gif" {
                        self.importGIF(from: url)
                    }
                    else if fileExtension == "mp4" || fileExtension == "mov" {
                        self.importVideo(from: url)
                    }
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
                self.loopsTextField.stringValue = String(GIFHandler.defaultLoops)
                
                self.imageCollectionView.reloadData()
                self.deselectAll()
            }
        }
    }
    
    // Preview
    @IBAction func previewButtonClicked(sender: AnyObject?) {
        let validate = self.findAndValidateUIValues()
        
        if validate.error {
            return
        }
        
        self.loadingView.isHidden = false
        
        DispatchQueue.global(qos: .utility).async {
            self.previewImage = GIFHandler.createGIF(with: validate.gif.frames, loops: validate.gif.loops, watermark: false)
            
            DispatchQueue.main.async {
                self.loadingView.isHidden = true
                self.performSegue(withIdentifier: "ShowPreview", sender: self)
            }
        }
    }
    
    
    // MARK: Helpers
    // Validates values from UI and returns them
    func findAndValidateUIValues() -> (error: Bool, gif: GIFRepresentation) {

        let empRep = GIFRepresentation()
        let errorReturn = (error: true, gif: empRep)
        
        guard let loops = Int(loopsTextField.stringValue) else {
            showError("Invalid value for loop count (Zero or positive integer).")
            return errorReturn
        }
        
        // Remove empty images
        let tmpFrames:[GIFFrame] = currentFrames.filter({ (frame) -> Bool in
            return frame.image != nil
        })
        
        if tmpFrames.count == 0 {
            showError("No frames to export.")
            return errorReturn
        }
        
        // Success!
        return (error: false, gif: GIFRepresentation(frames: tmpFrames, loops: loops))
    }
    
    // Imports a gif from a given location
    func importGIF(from: URL) {
        if let image = NSImage(contentsOf: from) {
            DispatchQueue.global(qos: .utility).async { // Perform in background to not break UI
                // Set values from the .GIF
                GIFHandler.loadGIF(with: image, onFinish: { rep in
                    self.currentFrames = rep.frames
                    self.loopsTextField.stringValue = String(rep.loops)
                    
                    DispatchQueue.main.async { // Update UI in main
                        self.selectedRow = nil
                        self.imageCollectionView.reloadData()
                    }
                })
            }
        }
        else {
            self.importError()
        }
    }
    
    // Imports MP4 from given location
    func importVideo(from: URL) {
        
        showAlert(title: "Importing..", msg: "This might take a while.")
        self.loadingView.isHidden = false
        
        DispatchQueue.global(qos: .utility).async {
            GIFHandler.loadVideo(with: from, withFPS: 5, onFinish: { representation in
                if representation.frames.count < 1 {
                    DispatchQueue.main.async {
                        self.importError()
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.currentFrames = representation.frames
                    self.loopsTextField.stringValue = String(representation.loops)
                    
                    self.selectedRow = nil
                    self.imageCollectionView.reloadData()
                    self.loadingView.isHidden = true
                }
            })
        }
    }

    // Exports given gif to given url
    func exportGIF(to: URL, gif: GIFRepresentation) {
        self.loadingView.isHidden = false
        
        DispatchQueue.global(qos: .utility).async {
            // GIFHandler.createGIF(with: preview.frames, loops: preview.loops)
            GIFHandler.createAndSaveGIF(with: gif.frames, savePath: to, loops: gif.loops)
            NSWorkspace.shared().activateFileViewerSelecting([to])
            
            DispatchQueue.main.async {
                self.loadingView.isHidden = true
            }
        }
    }
    
    // Adds NotificationCenter listeners
    func setupNotificationListeners() {
        // Listeners for events regarding frames and images
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.reloadImages),
                                               name: MainViewController.editingEndedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.documentFramesLoaded(notification:)),
                                               name: MainViewController.loadedDocumentFramesNotificationName, object: nil)
        
        // GIFHandler events
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.gifError(sender:)),
                                               name: GIFHandler.errorNotificationName, object: nil)
    }
    
    // Frames loaded using 'Open with...' menu
    func documentFramesLoaded(notification: NSNotification) {
        if let values = notification.userInfo?["info"] as? GIFRepresentation {
            self.currentFrames = values.frames
            self.loopsTextField.stringValue = String(values.loops)
            
            self.selectedRow = nil
            self.imageCollectionView.reloadData()
        }
    }
    
    // Shows editing window with given image index
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
    
    // MARK: Actions
    // Reverses alle frames
    func reverseFrames() {
        self.currentFrames.reverse()
        self.reloadImages()
    }
    
    func setAllFrameDurations() {
        let alert = FancyAlert()
        alert.messageText = "Set frame duration"
        alert.informativeText = "What frame duration do you want to set?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Set frame durations")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = String(GIFHandler.defaultFrameDuration)
        
        alert.accessoryView = input
        
        alert.beginSheetModal(for: self.view.window!) { (resp) in
            if resp == NSAlertFirstButtonReturn {
                guard var duration = Double(input.stringValue) else { // Could not parse as Double
                    self.showError("Frame duration must be a number!")
                    return
                }
                
                if duration < GIFHandler.minFrameDuration { // Limit
                    duration = GIFHandler.minFrameDuration
                }
                
                self.currentFrames.forEach({ (frame) in
                    frame.duration = duration
                })
                self.reloadImages()
            }
            else { // Cancel
            }
        }
    }
}
