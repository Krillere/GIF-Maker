//
//  ViewController.swift
//  GIF
//
//  Created by Christian Lundtofte on 14/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    // MARK: Fields
    
    // Constants
    static let backgroundColor = NSColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 1.0)
    
    static let removeFrameNotificationName = NSNotification.Name(rawValue: "RemoveFrame")
    static let editFrameNotificationName = NSNotification.Name(rawValue: "EditFrame")
    static let imageClickedNotificationName = NSNotification.Name(rawValue: "ImageClicked")
    static let imageChangedNotificationName = NSNotification.Name(rawValue: "ImageChanged")
    static let editingEndedNotificationName = NSNotification.Name(rawValue: "EditingEnded")
    
    static let menuItemImportNotificationName = NSNotification.Name(rawValue: "MenuItemImport")
    static let menuItemExportNotificationName = NSNotification.Name(rawValue: "MenuItemExport")
    static let menuItemAddFrameNotificationName = NSNotification.Name(rawValue: "MenuItemAddFrame")
    static let menuItemPreviewNotificationName = NSNotification.Name(rawValue: "MenuItemPreview")
    static let menuItemResetNotificationName = NSNotification.Name(rawValue: "MenuItemReset")
    static let menuItemEditNotificationName = NSNotification.Name(rawValue: "MenuItemEdit")
    
    // UI elements
    @IBOutlet var imageCollectionView:NSCollectionView!
    @IBOutlet var frameDurationTextField:NSTextField!
    @IBOutlet var FPSLabel:NSTextField!
    @IBOutlet var addFrameButton:NSButton!
    @IBOutlet var loopsTextField:NSTextField!
    
    // Fields used in UI handling
    var currentFrames:[GIFFrame] = [GIFFrame.emptyFrame()] // Allows null as they are shown as empty frames. Default is 1 empty image, to show something in UI
    var selectedRow:IndexPath? = nil // Needed for inserting and removing item
    var indexPathsOfItemsBeingDragged: Set<IndexPath>! // Paths of items being dragged (If dragging inside the app)
    var editingWindowController:NSWindowController?
    
    // Preview variables
    var previewImages:[NSImage] = []
    var previewLoops:Int = GIFHandler.defaultLoops
    var previewFrameDuration:Float = GIFHandler.defaultFrameDuration
    
    
    // MARK: View setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        
        // Listeners for events regarding frames and images
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.removeFrameCalled(sender:)),
                                               name: ViewController.removeFrameNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.clickedImageView(sender:)),
                                               name: ViewController.imageClickedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.imageDraggedToImageView(sender:)),
                                               name: ViewController.imageChangedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reloadImages),
                                               name: ViewController.editingEndedNotificationName, object: nil)
        
        // UI events
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.loadGIFButtonClicked(sender:)),
                                               name: ViewController.menuItemImportNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.exportGIFButtonClicked(sender:)),
                                               name: ViewController.menuItemExportNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.addFrameButtonClicked(sender:)),
                                               name: ViewController.menuItemAddFrameNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.previewButtonClicked(sender:)),
                                               name: ViewController.menuItemPreviewNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.resetButtonClicked(sender:)),
                                               name: ViewController.menuItemResetNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.editButtonClicked(sender:)),
                                               name: ViewController.menuItemEditNotificationName, object: nil)
        
        // GIFHandler events
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.gifError(sender:)),
                                               name: GIFHandler.errorNotificationName, object: nil)
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
        }

    }
    
    func reloadImages() {
        imageCollectionView.reloadData()
    }
    
    
    // MARK: Buttons
    // Adds a new frame
    @IBAction func addFrameButtonClicked(sender: AnyObject?) {
        if let indexPath = selectedRow { // Add after selectedRow
            currentFrames.insert(GIFFrame.emptyFrame(), at: indexPath.item+1)
            selectedRow = IndexPath(item: indexPath.item+1, section: 0)
        }
        else { // Add empty frame
            currentFrames.append(GIFFrame.emptyFrame())
        }

        self.imageCollectionView.reloadData()
    }
    
    // Edit button clicked
    @IBAction func editButtonClicked(sender: AnyObject?) {
        if editingWindowController == nil {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            editingWindowController = storyboard.instantiateController(withIdentifier: "EditingWindow") as? NSWindowController
        }
        
        if let contentViewController = editingWindowController?.contentViewController as? EditViewController {
            contentViewController.setFrames(frames: self.currentFrames)
        }
        
        editingWindowController?.showWindow(self)
    }
    
    // Export a gif
    @IBAction func exportGIFButtonClicked(sender: AnyObject?) {
        guard let loops = Int(loopsTextField.stringValue) else {
            showError("Invalid value for loop count.")
            return
        }
        guard let spf = Float(frameDurationTextField.stringValue) else {
            showError("Invalid value for frame duration.")
            return
        }
        
        // Remove empty images
        var tmpImages:[NSImage] = []
        for frame in currentFrames {
            if let img = frame.image {
                tmpImages.append(img)
            }
        }
        
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["gif"]
        panel.begin { (res) in
            if res == NSFileHandlingPanelOKButton {
                if let url = panel.url {
                    GIFHandler.createAndSaveGIF(with: tmpImages, savePath: url, loops: loops, secondsPrFrame: spf)
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
                self.currentFrames = [GIFFrame.emptyFrame()]
                self.frameDurationTextField.stringValue = String(GIFHandler.defaultFrameDuration)
                self.loopsTextField.stringValue = String(GIFHandler.defaultLoops)
                self.imageCollectionView.reloadData()
                self.deselectAll()
            }
        }
    }
    
    // Preview
    @IBAction func previewButtonClicked(sender: AnyObject?) {
        guard let loops = Int(loopsTextField.stringValue),
            let spf = Float(frameDurationTextField.stringValue) else {
                return
        }
        
        if spf < 0 {
            showError("Frame duration must be a positive number.")
            return
        }
        
        // Remove empty images
        var tmpImages:[NSImage] = []
        for frame in currentFrames {
            if let img = frame.image {
                tmpImages.append(img)
            }
        }
        
        if tmpImages.count == 0 {
            showError("No frames to preview!")
            return
        }
        
        self.previewLoops = loops
        self.previewFrameDuration = spf
        self.previewImages = tmpImages
        
        self.performSegue(withIdentifier: "ShowPreview", sender: self)
    }
    
    
    // MARK: Helpers
    // Imports a gif from a given location
    func importGIF(from: URL) {
        if let image = NSImage(contentsOf: from) {
            // Set values from the .GIF
            let newValues = GIFHandler.loadGIF(with: image)
            
            self.currentFrames = newValues.frames
            self.frameDurationTextField.stringValue = String(newValues.secondsPrFrame)
            self.loopsTextField.stringValue = String(newValues.loops)
            
            self.selectedRow = nil
            self.imageCollectionView.reloadData()
        }
    }
    
    // MARK: NotificationCenter calls (Mainly by UI components)
    // A frame wants to be removed (Get index of sender, and remove from 'currentImages')
    func removeFrameCalled(sender: NSNotification) {
        guard let object = sender.object as? FrameCollectionViewItem else { return }
        
        // Remove the index and reload everything
        let index = object.itemIndex
        currentFrames.remove(at: index)
        
        deselectAll()
        imageCollectionView.reloadData()
    }

    // An image was dragged to an imageView
    // Replace the image at the views location to the new one
    func imageDraggedToImageView(sender: NSNotification) {
        guard let imgView = sender.object as? DragNotificationImageView,
              let owner = imgView.ownerCollectionViewItem,
              let frame = imgView.gifFrame else { return }
        
        currentFrames[owner.itemIndex] = frame
        self.selectedRow = nil
        self.imageCollectionView.reloadData()
    }
    
    // An ImageView was clicked
    // Show an open dialog and insert image in view and 'currentImages'
    func clickedImageView(sender: NSNotification) {
        guard let imgView = sender.object as? DragNotificationImageView,
              let owner = imgView.ownerCollectionViewItem else { return }
        
        // Show panel
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "gif", "tiff"]
        panel.beginSheetModal(for: self.view.window!) { (response) -> Void in
            
            // Insert image into imageview and 'currentImages' and reload
            if response == NSFileHandlingPanelOKButton {
                let URL = panel.url
                if URL != nil {
                    if let image = NSImage(contentsOf: URL!) {
                        let frame = GIFFrame(image: image)
                        self.currentFrames[owner.itemIndex] = frame
                    }
                    self.imageCollectionView.reloadData()
                }
            }
            
            imgView.resignFirstResponder()
            self.addFrameButton.becomeFirstResponder()
        }
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
