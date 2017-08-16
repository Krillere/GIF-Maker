//
//  PixelImageView.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 25/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

fileprivate struct PixelChange {
    var location: (x: Int, y: Int)!
    var oldColor: NSColor!
    var newColor: NSColor!
}

fileprivate class UndoOperation {
    var changes:[PixelChange] = []
}

class PixelImageView: NSImageView {
    
    // Drawing variables
    fileprivate var drawing = false
    fileprivate var previousDrawingPosition:(x: Int, y: Int)?
    
    // Undo / redo variables
    fileprivate var undoOperations:[UndoOperation] = []
    fileprivate var redoOperations:[UndoOperation] = []
    fileprivate var currentUndoOperation:UndoOperation?
    
    fileprivate static let maxUndoRedoCount = 50
    
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
        
        self.currentUndoOperation = UndoOperation() // New
        
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
        
        // Add current undo to list
        if let op = self.currentUndoOperation {
            self.undoOperations.append(op)
            self.currentUndoOperation = nil
        }
    }
    
    
    // MARK: Undo and Redo
    func undo() {
        if let undoOp = self.undoOperations.last {
            undoOp.changes.reversed().forEach({ (change) in
                self.setPixelColor(color: change.oldColor, x: change.location.x, y: change.location.y)
            })
            self.undoOperations.removeLast()
            self.redoOperations.append(undoOp)
            
            if self.redoOperations.count > PixelImageView.maxUndoRedoCount {
                self.redoOperations.removeFirst()
            }
        }
    }
    
    func redo() {
        if let redoOp = self.redoOperations.last {
            redoOp.changes.reversed().forEach({ (change) in
                self.setPixelColor(color: change.newColor, x: change.location.x, y: change.location.y)
            })
            self.redoOperations.removeLast()
            self.undoOperations.append(redoOp)
        }
    }
    
    func resetUndoRedo() {
        self.redoOperations.removeAll()
        self.undoOperations.removeAll()
    }
    
    
    // MARK: Helpers
    // Images and NSViews have flipped Y coordinates, this turns them
    func pointInFlippedRect(inPoint: NSPoint, aRect: NSRect) -> NSPoint {
        return NSMakePoint(inPoint.x, NSHeight(aRect) - inPoint.y)
    }
    
    // Converts window event position go pixel coordinates
    func convertWindowToPixels(windowLoc: NSPoint) -> (x: Int, y: Int) {
        guard let image = self.image else { return (x: 0, y: 0) }
        guard let imgRep = image.getBitmapRep() else { return (x: 0, y: 0) }
        
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
        
        // Create undo operation
        guard let curColor = getPixelColor(x: x, y: y) else {
            return
        }
        
        self.currentUndoOperation?.changes.append(PixelChange(location: (x: x, y: y), oldColor: curColor, newColor: DrawingOptionsHandler.shared.drawingColor))
        
        if self.undoOperations.count > PixelImageView.maxUndoRedoCount {
            self.undoOperations.removeFirst()
        }
        
        
        // Draw
        setPixelColor(color: DrawingOptionsHandler.shared.drawingColor, x: x, y: y)
    }
    
    // Sets a color at a given coordinate
    func setPixelColor(color: NSColor, x: Int, y: Int) {
        guard let image = self.image,
            let imgRep = image.getBitmapRep() else { return }
        
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
        guard let imgRep = image.getBitmapRep() else { return nil }
        
        return imgRep.colorAt(x:x, y:y)
    }
}
