//
//  ViewController.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 13/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class EditViewController: NSViewController, ZoomViewDelegate {
    
    // MARK: Fields
    @IBOutlet var imageScrollView:NSScrollView!
    
    @IBOutlet var imageBackgroundView:ZoomView!
    @IBOutlet var frameNumberLabel:NSTextField!
    @IBOutlet var currentFrameImageView:PixelImageView!
    @IBOutlet var previousFrameButton:NSButton!
    @IBOutlet var nextFrameButton:NSButton!
    
    var drawingOptionsWindowController:NSWindowController?
    
    var frames:[GIFFrame] = []
    var currentFrameNumber:Int = 0
    

    // MARK: ViewController stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.windowResized), name: NSNotification.Name.NSWindowDidResize, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.imageBackgroundColorUpdated), name: DrawingOptionsHandler.backgroundColorChangedNotificationName, object: nil)
        
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
        
        showDrawingOptionsWindow()
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    
    // MARK: Zoom
    func zoomChanged(magnification: CGFloat) {
        
        let scrollWidth = imageScrollView.frame.width
        let scrollHeight = imageScrollView.frame.height
        let imgWidth = currentFrameImageView.frame.width
        let imgHeight = currentFrameImageView.frame.height
        if imgHeight < scrollHeight || imgWidth < scrollWidth {
            currentFrameImageView.center(inView: imageBackgroundView)
        }
        else {
            currentFrameImageView.setFrameOrigin(NSMakePoint(0, 0))
        }
        
        
        updateScrollViewSize()
    }
    
    
    // MARK: UI
    func updateFrameLabel() {
        self.frameNumberLabel.stringValue = "\(currentFrameNumber+1)/\(frames.count)"
        
        previousFrameButton.isHidden = false
        nextFrameButton.isHidden = false
        frameNumberLabel.isHidden = false
    }
    

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
        let scrollWidth = imageBackgroundView.frame.width
        let scrollHeight = imageBackgroundView.frame.height
        let imgWidth = currentFrameImageView.frame.width
        let imgHeight = currentFrameImageView.frame.height
        
        var newSize = NSMakeSize(imageBackgroundView.frame.width, imageBackgroundView.frame.height)
        
        if imgHeight > scrollHeight {
            newSize.height = imgHeight+20
        }
        
        if imgWidth > scrollWidth {
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
    
    func showDrawingOptionsWindow() {
        if drawingOptionsWindowController == nil {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            drawingOptionsWindowController = storyboard.instantiateController(withIdentifier: "DrawingOptionsWindow") as? NSWindowController
            drawingOptionsWindowController?.showWindow(self)
        }
        else {
            drawingOptionsWindowController!.showWindow(self)
        }
        
        if let drawingWindow = drawingOptionsWindowController?.window,
            let myWindow = self.view.window {
            drawingWindow.setFrameOrigin(NSMakePoint(myWindow.frame.origin.x+myWindow.frame.size.width+10, myWindow.frame.origin.y))

            drawingWindow.makeKeyAndOrderFront(self)
        }
    }
    
    // Called when the user changes the background color of the image
    func imageBackgroundColorUpdated() {
        currentFrameImageView.backgroundColor = DrawingOptionsHandler.shared.imageBackgroundColor
    }
    
    
    // MARK: Buttons
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
    
    @IBAction func addImageButtonClicked(sender: AnyObject?) {
    }
    
    @IBAction func addTextButtonClicked(sender: AnyObject?) {
    }
    
    
    // MARK: Helpers
    // Imports a gif from a given location
    func importGIF(from: URL) {
        if let image = NSImage(contentsOf: from) {
            // Set values from the .GIF
            let newValues = GIFHandler.loadGIF(with: image)
            self.frames = newValues.frames
            self.currentFrameNumber = 0
            
            updateFrameLabel()
            
            showFrame(frame: self.frames[self.currentFrameNumber])
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

