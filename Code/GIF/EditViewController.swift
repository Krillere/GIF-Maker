//
//  ViewController.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 13/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class EditViewController: NSViewController, ZoomViewDelegate, NSWindowDelegate {
    
    // MARK: Fields
    // UI
    @IBOutlet var imageScrollView:NSScrollView!
    
    @IBOutlet var imageBackgroundView:ZoomView!
    @IBOutlet var frameNumberLabel:NSTextField!
    @IBOutlet var currentFrameImageView:PixelImageView!
    @IBOutlet var previousFrameButton:NSButton!
    @IBOutlet var nextFrameButton:NSButton!
    
    @IBOutlet var eyedropperButtonCell:FancyButtonCell!
    
    @IBOutlet var colorPicker:NSColorWell!
    @IBOutlet var backgroundColorPicker:NSColorWell!
    
    @IBOutlet var undoButton:NSButton!
    @IBOutlet var redoButton:NSButton!
    
    var drawingOptionsWindowController:NSWindowController?
    
    // Frames and frame count
    var frames:[GIFFrame] = []
    var currentFrameNumber:Int = 0
    var initialFrameNumber:Int?
    

    // MARK: ViewController stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addEditorMenu()
        self.allowColorPanelAlpha()
        
        // Event listeners (Color changes and window resizes)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(EditViewController.windowResized),
                                               name: NSNotification.Name.NSWindowDidResize,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.imageBackgroundColorUpdated),
                                               name: DrawingOptionsHandler.backgroundColorChangedNotificationName,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.usedEyeDropper),
                                               name: DrawingOptionsHandler.usedEyeDropperNotificationName,
                                               object: nil)

        self.colorPicker.addObserver(self, forKeyPath: "color", options: .new, context: nil)
        self.backgroundColorPicker.addObserver(self, forKeyPath: "color", options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.colorChangedOutside), name: DrawingOptionsHandler.colorChangedNotificationName, object: nil)
        
        // UI setup
        self.backgroundColorPicker.color = DrawingOptionsHandler.shared.imageBackgroundColor
        
        self.view.wantsLayer = true
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Sets up UI controls
        imageBackgroundView.backgroundColor = ViewController.backgroundColor
        currentFrameImageView.backgroundColor = DrawingOptionsHandler.shared.imageBackgroundColor
        
        imageBackgroundView.zoomView = currentFrameImageView
        imageBackgroundView.delegate = self
        imageScrollView.backgroundColor = ViewController.backgroundColor
        
        self.view.backgroundColor = ViewController.backgroundColor
        
        // Sets up window border
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.isMovableByWindowBackground = true
        self.view.window?.titleVisibility = NSWindowTitleVisibility.hidden
        self.view.window?.backgroundColor = ViewController.backgroundColor
        self.view.window?.acceptsMouseMovedEvents = true
        self.view.window?.delegate = self
        
        // Show specific frame if chosen from main window
        if let frameIndex = self.initialFrameNumber {
            self.currentFrameNumber = frameIndex
            self.showFrame(frame: self.frames[frameIndex])
            self.updateFrameLabel()
        }
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    // Forces image update in main view
    func windowWillClose(_ notification: Notification) {
        if NSColorPanel.sharedColorPanelExists() {
            let panel = NSColorPanel.shared()
            panel.close()
        }
        
        NotificationCenter.default.post(name: ViewController.editingEndedNotificationName, object: nil)
        
        self.removeEditorMenu()
    }
    
    
    // MARK: Values changing
    // Observe changes
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "color" {
            guard let object = object as? NSColorWell else { return }
            
            if object == colorPicker {
                DrawingOptionsHandler.shared.drawingColor = colorPicker.color
            }
            else if object == backgroundColorPicker {
                DrawingOptionsHandler.shared.imageBackgroundColor = backgroundColorPicker.color
                NotificationCenter.default.post(name: DrawingOptionsHandler.backgroundColorChangedNotificationName, object: nil)
            }
        }
    }
    
    // Called when something changes the color from outside this viewcontroller
    func colorChangedOutside() {
        colorPicker.color = DrawingOptionsHandler.shared.drawingColor
    }
    
    // Called when eyedropper tool selects color
    func usedEyeDropper() {
        DrawingOptionsHandler.shared.isPickingColor = false
        
        self.eyedropperButtonCell.showBackground = DrawingOptionsHandler.shared.isPickingColor
        self.eyedropperButtonCell.redraw()
    }
    
    // When window resizes, make sure image is center
    func windowResized() {
        handleCenterImage()
    }
    
    // MARK: ZoomViewDelegate
    func zoomChanged(magnification: CGFloat) {
        updateScrollViewSize()
        
        currentFrameImageView.center(inView: imageBackgroundView)
    }

    
    
    // MARK: Buttons
    @IBAction func eraserButtonClicked(sender: AnyObject?) {
        colorPicker.color = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    }
    
    @IBAction func eyedropperButtonClicked(sender: AnyObject?) {
        DrawingOptionsHandler.shared.isPickingColor = !DrawingOptionsHandler.shared.isPickingColor
        
        self.eyedropperButtonCell.showBackground = DrawingOptionsHandler.shared.isPickingColor
        self.eyedropperButtonCell.redraw()
    }
    
    @IBAction func undoButtonClicked(sender: AnyObject?) {
        self.currentFrameImageView.undo()
    }
    
    @IBAction func redoButtonClicked(sender: AnyObject?) {
        self.currentFrameImageView.redo()
    }

    
    // MARK: UI
    // Creates a menu with editor related items
    func addEditorMenu() {
        guard let menu = NSApplication.shared().mainMenu else { return }
        let newItem = NSMenuItem(title: "Editor", action: nil, keyEquivalent: "")
        let newMenu = NSMenu(title: "Editor")
        
        let undoItem = NSMenuItem(title: "Undo", action: #selector(EditViewController.undoButtonClicked(sender:)), keyEquivalent: "")
        undoItem.keyEquivalent = "z"
        undoItem.keyEquivalentModifierMask = .command
        
        let redoItem = NSMenuItem(title: "Redo", action: #selector(EditViewController.redoButtonClicked(sender:)), keyEquivalent: "")
        redoItem.keyEquivalent = "z"
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        
        let eraserItem = NSMenuItem(title: "Eraser", action: #selector(EditViewController.eraserButtonClicked(sender:)), keyEquivalent: "")
        let eyedropperItem = NSMenuItem(title: "Eyedropper", action: #selector(EditViewController.eyedropperButtonClicked(sender:)), keyEquivalent: "")
        
        let closeItem = NSMenuItem(title: "Close", action: #selector(EditViewController.closeWindow), keyEquivalent: "")
        closeItem.keyEquivalent = "w"
        closeItem.keyEquivalentModifierMask = .command
        
        newMenu.addItem(undoItem)
        newMenu.addItem(redoItem)
        newMenu.addItem(NSMenuItem.separator())
        newMenu.addItem(eraserItem)
        newMenu.addItem(eyedropperItem)
        newMenu.addItem(NSMenuItem.separator())
        newMenu.addItem(closeItem)
        
        newItem.submenu = newMenu
        menu.insertItem(newItem, at: 2)
    }
    
    // Removes the editor menu item
    func removeEditorMenu() {
        guard let menu = NSApplication.shared().mainMenu else { return }
        if let item = menu.item(withTitle: "Editor") {
            menu.removeItem(item)
        }
    }
    
    // Closes the window
    func closeWindow() {
        self.view.window?.close()
    }
    
    // Updates the frame counter label
    func updateFrameLabel() {
        self.frameNumberLabel.stringValue = "\(currentFrameNumber+1)/\(frames.count)"
        
        previousFrameButton.isHidden = false
        nextFrameButton.isHidden = false
        frameNumberLabel.isHidden = false
    }
    
    // Shows a given GIFFrame
    func showFrame(frame: GIFFrame) {
        guard let image = frame.image else { return }
        
        let maxWidth = imageBackgroundView.bounds.width
        let maxHeight = imageBackgroundView.bounds.height
        let width = image.size.width
        let height = image.size.height
        
        let tmp = calculateAspectRatioFit(srcWidth: width, srcHeight: height, maxWidth: maxWidth, maxHeight: maxHeight)
        
        currentFrameImageView.frame = NSRect(x: 0, y: 0, width: tmp.width, height: tmp.height)
        currentFrameImageView.image = image
        currentFrameImageView.isHidden = false
        
        handleCenterImage()
    }
    
    // Updates the scrollview contentView size, if necessary
    func updateScrollViewSize() {
        let imgWidth = currentFrameImageView.frame.width
        let imgHeight = currentFrameImageView.frame.height
        
        var newSize = NSMakeSize(imageScrollView.frame.width, imageScrollView.frame.height)

        if imgHeight > newSize.height {
            newSize.height = imgHeight+20
        }
        
        if imgWidth > newSize.width {
            newSize.width = imgWidth+20
        }
        
        imageBackgroundView.setFrameSize(newSize)
    }
    
    // Centers the image and redo the zoom
    func handleCenterImage() {
        if imageBackgroundView.previousZoomSize != nil {
            imageBackgroundView.redoZoom()
        }
        else {
            currentFrameImageView.center(inView: imageBackgroundView)
        }
    }

    // Called when the user changes the background color of the image
    func imageBackgroundColorUpdated() {
        currentFrameImageView.backgroundColor = DrawingOptionsHandler.shared.imageBackgroundColor
    }
    
    
    func setFrames(frames: [GIFFrame]) {
        self.frames = frames
        self.currentFrameNumber = 0
        
        updateFrameLabel()
        
        showFrame(frame: self.frames[self.currentFrameNumber])
    }
    
    @IBAction func nextFrameButtonClicked(sender: AnyObject?) {
        if self.currentFrameNumber+1 > self.frames.count-1 {
            self.currentFrameNumber = 0
        }
        else {
            self.currentFrameNumber += 1
        }
        
        self.showFrame(frame: self.frames[self.currentFrameNumber])
        self.updateFrameLabel()
    }
    
    @IBAction func previousFrameButtonClicked(sender: AnyObject?) {
        if self.currentFrameNumber-1 < 0 {
            self.currentFrameNumber = self.frames.count-1
        }
        else {
            self.currentFrameNumber -= 1
        }
        
        self.showFrame(frame: self.frames[self.currentFrameNumber])
        self.updateFrameLabel()
    }
    
    // Buttons on top of color wells
    @IBAction func drawingColorWellClicked(sender: AnyObject?) {
        colorPicker.performClick(sender)
        allowColorPanelAlpha()
    }
    
    @IBAction func backgroundColorWellClicked(sender: AnyObject?) {
        backgroundColorPicker.performClick(sender)
        allowColorPanelAlpha()
    }
    
    
    // MARK: Helpers
    func allowColorPanelAlpha() {
        if NSColorPanel.sharedColorPanelExists() {
            let panel = NSColorPanel.shared()
            panel.showsAlpha = true
        }
    }

    // Based on http://stackoverflow.com/a/14731922
    func calculateAspectRatioFit(srcWidth: CGFloat, srcHeight: CGFloat, maxWidth: CGFloat, maxHeight: CGFloat) -> (width: CGFloat, height: CGFloat) {
        if srcWidth < maxWidth && srcHeight < maxHeight {
            return (width: srcWidth, height: srcHeight)
        }
        
        let ratio = min(maxWidth/srcWidth, maxHeight/srcHeight)
        return (width: srcWidth*ratio, height: srcHeight*ratio)
    }

}

