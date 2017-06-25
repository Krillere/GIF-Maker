//
//  PixelImageView.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 25/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class PixelImageViewUndoOperation {
    var location: (x: Int, y: Int)?
    var oldColor: NSColor?
    var newColor: NSColor?
}

class PixelImageView: NSImageView {
    var drawing = false
    var previousDrawingPosition:(x: Int, y: Int)?
    
    var undoOperations:[PixelImageViewUndoOperation] = []
    
    
    // Disables antialiasing (No smoothing, clean pixels)
    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current()?.imageInterpolation = .none
        super.draw(dirtyRect)
        NSGraphicsContext.restoreGraphicsState()
    }

    
    // MARK: Mouse
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
    
    // Draw pixel and begin drag
    override func mouseDown(with event: NSEvent) {
        if DrawingOptionsHandler.shared.isPickingColor {
            let windowLoc = event.locationInWindow
            let pixelLoc = self.convertWindowToPixels(windowLoc: windowLoc)
            if let color = self.getPixelColor(x: pixelLoc.x, y: pixelLoc.y) {
                DrawingOptionsHandler.shared.drawingColor = color
            }
            
            DrawingOptionsHandler.shared.isPickingColor = false
            NotificationCenter.default.post(name: DrawingOptionsHandler.colorChangedNotificationName, object: nil)
            
            return
        }
        
        
        drawing = true
        let windowLoc = event.locationInWindow
        let pixelLoc = self.convertWindowToPixels(windowLoc: windowLoc)
        previousDrawingPosition = pixelLoc
        
        drawAtCoordinate(x: pixelLoc.x, y: pixelLoc.y)
    }
    
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
        
        if pixelLoc.x != previousDrawingPosition!.x || pixelLoc.y != previousDrawingPosition!.y {
            drawAtCoordinate(x: pixelLoc.x, y: pixelLoc.y)
            previousDrawingPosition = pixelLoc
        }
    }

    // Stop drawing
    override func mouseUp(with event: NSEvent) {
        drawing = false
    }
    
    
    // MARK: Undo and Redo
    
    
    // MARK: Helpers
    // Images and NSViews have flipped Y coordinates, this turns them
    func pointInFlippedRect(inPoint: NSPoint, aRect: NSRect) -> NSPoint {
        return NSMakePoint(inPoint.x, NSHeight(aRect) - inPoint.y)
    }
    
    
    // MARK: Drawing
    // Draw current color at coordinate
    func drawAtCoordinate(x: Int, y: Int) {
        setPixelColor(color: DrawingOptionsHandler.shared.drawingColor, x: x, y: y)
    }
    
    // Sets a color at a given coordinate
    func setPixelColor(color: NSColor, x: Int, y: Int) {
        guard let image = self.image else { Swift.print("Nope1"); return }
        guard let imgRep = image.representations[0] as? NSBitmapImageRep else { Swift.print("Nope2"); return }
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
    
    func getPixelColor(x: Int, y: Int) -> NSColor? {
        guard let image = self.image else { Swift.print("Nope1"); return nil }
        guard let imgRep = image.representations[0] as? NSBitmapImageRep else { Swift.print("Nope2"); return nil }
        
        return imgRep.colorAt(x:x, y:y)
    }
}
