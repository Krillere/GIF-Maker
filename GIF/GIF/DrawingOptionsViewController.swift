//
//  DrawingOptionsViewController.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 26/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class DrawingOptionsViewController: NSViewController {

    @IBOutlet var colorPicker:NSColorWell!
    @IBOutlet var backgroundColorPicker:NSColorWell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Event listeners
        colorPicker.addObserver(self, forKeyPath: "color", options: .new, context: nil)
        backgroundColorPicker.addObserver(self, forKeyPath: "color", options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(DrawingOptionsViewController.colorChangedOutside), name: DrawingOptionsHandler.colorChangedNotificationName, object: nil)
        
        // UI setup
        backgroundColorPicker.color = DrawingOptionsHandler.shared.imageBackgroundColor
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.backgroundColor = ViewController.backgroundColor
        
        // Sets up window
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.isMovableByWindowBackground = true
        self.view.window?.titleVisibility = NSWindowTitleVisibility.hidden
        self.view.window?.backgroundColor = ViewController.backgroundColor
        self.view.window?.acceptsMouseMovedEvents = true
    }
    
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
    
    // MARK: Buttons
    @IBAction func eraserButtonClicked(sender: AnyObject?) {
        colorPicker.color = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    @IBAction func undoButtonClicked(sender: AnyObject?) {
        
    }
    
    @IBAction func redoButtonClicked(sender: AnyObject?) {
        
    }
    
    @IBAction func eyedropperButtonClicked(sender: AnyObject?) {
        DrawingOptionsHandler.shared.isPickingColor = !DrawingOptionsHandler.shared.isPickingColor
    }
}
