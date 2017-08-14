//
//  PixelImageView.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 25/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

fileprivate class PixelImageViewUndoOperation {
    var location: (x: Int, y: Int)!
    var oldColor: NSColor!
    var newColor: NSColor!
    
    init(location: (x: Int, y: Int), oldColor: NSColor, newColor: NSColor) {
        self.location = location
        self.oldColor = oldColor
        self.newColor = newColor
    }
}

class PixelImageView: NSImageView {
    
    // Drawing variables
    fileprivate var drawing = false
    fileprivate var previousDrawingPosition:(x: Int, y: Int)?
    
    // Undo / redo variables
    fileprivate var undoOperations:[PixelImageViewUndoOperation] = []
    fileprivate var currentUndoOperation:PixelImageViewUndoOperation?
    
    
    // Disables antialiasing (No smoothing, clean pixels)
    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current()?.imageInterpolation = .none
        super.draw(dirtyRect)
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    // MARK: Mouse actions
    // Mouse down
    override func mouseDown(with event: NSEvent) {
        let windowLoc = event.locationInWindow
        let pixelLoc = self.convertWindowToPixels(windowLoc: windowLoc)
        
        // Pick a color
        if DrawingOptionsHandler.shared.isPickingColor {
            
            // Set color
            if let color = self.getPixelColor(x: pixelLoc.x, y: pixelLoc.y) {
                DrawingOptionsHandler.shared.drawingColor = color
            }
            
            // Disable eyedropper and send notifications
            DrawingOptionsHandler.shared.isPickingColor = false
            NotificationCenter.default.post(name: DrawingOptionsHandler.colorChangedNotificationName, object: nil)
            NotificationCenter.default.post(name: DrawingOptionsHandler.usedEyeDropperNotificationName, object: nil)
            
            return
        }
        
        // Draw
        drawing = true
        previousDrawingPosition = pixelLoc
        
        drawAtCoordinate(x: pixelLoc.x, y: pixelLoc.y)
    }
    
    // Mouse drag / mouse moved while mouse down
    // If we're drawing, draw new pixels
    override func mouseDragged(with event: NSEvent) {
        if !drawing {
            return
        }
        
        let windowLoc = event.locationInWindow
        let pixelLoc = self.convertWindowToPixels(windowLoc: windowLoc)
        
        if previousDrawingPosition == nil {
            drawAtCoordinate(x: pixelLoc.x, y: pixelLoc.y)
            previousDrawingPosition = pixelLoc
            return
        }
        
        // Only draw on changed pixel, no reason to draw more than necessary
        if pixelLoc.x != previousDrawingPosition!.x || pixelLoc.y != previousDrawingPosition!.y {
            drawAtCoordinate(x: pixelLoc.x, y: pixelLoc.y)
            previousDrawingPosition = pixelLoc
        }
    }

    // Mouse up
    override func mouseUp(with event: NSEvent) {
        drawing = false
        
        // Add to undo
    }
    
    
    // MARK: Undo and Redo
    func undo() {
        if let undoOp = self.undoOperations.first {
            self.setPixelColor(color: undoOp.oldColor, x: undoOp.location.x, y: undoOp.location.y)
            self.undoOperations.removeFirst()
        }
    }
    
    func redo() {
        
    }
    
    
    // MARK: Helpers
    // Images and NSViews have flipped Y coordinates, this turns them
    func pointInFlippedRect(inPoint: NSPoint, aRect: NSRect) -> NSPoint {
        return NSMakePoint(inPoint.x, NSHeight(aRect) - inPoint.y)
    }
    
    // Converts window event position go pixel coordinates
    func convertWindowToPixels(windowLoc: NSPoint) -> (x: Int, y: Int) {
        guard let image = self.image else { return (x: 0, y: 0) }
        guard let imgRep = image.representations[0] as? NSBitmapImageRep else { return (x: 0, y: 0) }
        
        let localLoc = self.pointInFlippedRect(inPoint: self.convert(windowLoc, from: nil), aRect: self.frame)
        
        let height = self.frame.height
        let width = self.frame.width
        let pixelHeight = CGFloat(imgRep.pixelsHigh)
        let pixelWidth = CGFloat(imgRep.pixelsWide)
        
        let clickX = Int(ceil((pixelWidth/width)*localLoc.x))-1
        let clickY = Int(ceil((pixelHeight/height)*localLoc.y))-1
        
        return (x: clickX, y: clickY)
    }
    
    
    // MARK: Drawing
    // Draw current color at coordinate
    func drawAtCoordinate(x: Int, y: Int) {
        guard let cur = getPixelColor(x: x, y: y) else {
            return
        }
        let undoOp = PixelImageViewUndoOperation(location: (x: x, y: y), oldColor: cur, newColor: DrawingOptionsHandler.shared.drawingColor)
        self.undoOperations.append(undoOp)
        
        if self.undoOperations.count > 25 {
            self.undoOperations = Array(self.undoOperations.dropFirst())
        }
        
        setPixelColor(color: DrawingOptionsHandler.shared.drawingColor, x: x, y: y)
    }
    
    // Sets a color at a given coordinate
    func setPixelColor(color: NSColor, x: Int, y: Int) {
        guard let image = self.image,
            let imgRep = image.representations[0] as? NSBitmapImageRep else { return }
        
        let red = Int(color.redComponent*255)
        let green = Int(color.greenComponent*255)
        let blue = Int(color.blueComponent*255)
        let alpha = Int(color.alphaComponent*255)
        var pix:[Int] = [red, green, blue, alpha]
        
        imgRep.setPixel(&pix, atX: x, y: y)
        
        let newImg = NSImage()
        newImg.addRepresentation(imgRep)
        self.image = newImg
    }
    
    // Returns NSColor at given coordinates
    func getPixelColor(x: Int, y: Int) -> NSColor? {
        guard let image = self.image else { Swift.print("Nope1"); return nil }
        guard let imgRep = image.representations[0] as? NSBitmapImageRep else { Swift.print("Nope2"); return nil }
        
        return imgRep.colorAt(x:x, y:y)
    }
}
