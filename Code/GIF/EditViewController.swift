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
    
    var drawingOptionsWindowController:NSWindowController?
    
    // Frames and frame count
    var frames:[GIFFrame] = []
    var currentFrameNumber:Int = 0
    var initialFrameNumber:Int?
    

    // MARK: ViewController stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allowColorPanelAlpha()
        
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

        colorPicker.addObserver(self, forKeyPath: "color", options: .new, context: nil)
        backgroundColorPicker.addObserver(self, forKeyPath: "color", options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.colorChangedOutside), name: DrawingOptionsHandler.colorChangedNotificationName, object: nil)
        
        // UI setup
        backgroundColorPicker.color = DrawingOptionsHandler.shared.imageBackgroundColor
        
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
    }
    
    
    // MARK: ZoomViewDelegate
    func zoomChanged(magnification: CGFloat) {
//        let scrollWidth = imageScrollView.frame.width
//        let scrollHeight = imageScrollView.frame.height
//        let imgWidth = currentFrameImageView.frame.width
//        let imgHeight = currentFrameImageView.frame.height
        
//        if imgHeight < scrollHeight || imgWidth < scrollWidth {
//            print("Mindre, centrerer \(CACurrentMediaTime())")
//            currentFrameImageView.center(inView: imageBackgroundView)
//        }
//        else {
//            print("Større, sætter i bund \(CACurrentMediaTime())")
//            currentFrameImageView.setFrameOrigin(NSMakePoint(0, 0))
//        }
        
        updateScrollViewSize()
        
        currentFrameImageView.center(inView: imageBackgroundView)
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
    
    // MARK: Buttons
    @IBAction func eraserButtonClicked(sender: AnyObject?) {
        colorPicker.color = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    }
    
    @IBAction func eyedropperButtonClicked(sender: AnyObject?) {
        DrawingOptionsHandler.shared.isPickingColor = !DrawingOptionsHandler.shared.isPickingColor
        
        self.eyedropperButtonCell.showBackground = DrawingOptionsHandler.shared.isPickingColor
        self.eyedropperButtonCell.redraw()
    }
    
    // MARK: Not implemented yet
    @IBAction func undoButtonClicked(sender: AnyObject?) {
        
    }
    
    @IBAction func redoButtonClicked(sender: AnyObject?) {
        
    }

    
    // MARK: UI
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

    // When window resizes, make sure image is center
    func windowResized() {
        handleCenterImage()
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

