//
//  GIFHandler.swift
//  GIF
//
//  Created by Christian Lundtofte on 14/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Foundation
import Cocoa

class GIFHandler {

    static let errorNotificationName = NSNotification.Name(rawValue: "GIFError")
    static let defaultLoops:Int = 0
    static let defaultFrameDuration:Float = 0.2
    
    // MARK: Loading gifs (Returns tuple with images, loop count and seconds/frame
    static func loadGIF(with image: NSImage) -> (frames: [GIFFrame], loops:Int, secondsPrFrame: Float) {
        let errorReturn:(frames: [GIFFrame], loops:Int, secondsPrFrame: Float) = (frames: [GIFFrame.emptyFrame()], loops: GIFHandler.defaultLoops, secondsPrFrame: GIFHandler.defaultFrameDuration)
        
        // Attempt to fetch the number of frames, frame duration, and loop count from the .gif
        guard let bitmapRep = image.representations[0] as? NSBitmapImageRep,
            let frameCount = (bitmapRep.value(forProperty: NSImageFrameCount) as? NSNumber)?.intValue,
            let loopCount = (bitmapRep.value(forProperty: NSImageLoopCount) as? NSNumber)?.intValue,
            let frameDuration = (bitmapRep.value(forProperty: NSImageCurrentFrameDuration) as? NSNumber)?.floatValue else {
                
            print("Error loading gif")
            NotificationCenter.default.post(name: errorNotificationName, object: self, userInfo: ["Error":"Could not load gif. The file does not contain the metadata required for a gif."])
            return errorReturn
        }

        
        
        var retFrames:[GIFFrame] = []
        
        // Iterate the frames, set the current frame on the bitmapRep and add this to 'retImages'
        for n in 0 ..< frameCount {
            bitmapRep.setProperty(NSImageCurrentFrame, withValue: NSNumber(value: n))
            
            if let data = bitmapRep.representation(using: .GIF, properties: [:]),
               let img = NSImage(data: data) {
                let frame = GIFFrame(image: img)
                retFrames.append(frame)
            }
        }
        
        return (frames: retFrames, loops: loopCount, secondsPrFrame: frameDuration)
    }
    
    
    // MARK: Making gifs from iamges
    // Creates and saves a gif
    static func createAndSaveGIF(with images: [NSImage], savePath: URL, loops: Int = GIFHandler.defaultLoops, secondsPrFrame: Float = GIFHandler.defaultFrameDuration) {
        // Get and save data at 'savePath'
        let data = GIFHandler.createGIFData(with: images, loops: loops, secondsPrFrame: secondsPrFrame)
        
        do {
            try data.write(to: savePath)
        }
        catch {
            NotificationCenter.default.post(name: errorNotificationName, object: self, userInfo: ["Error":"Could not save file: "+error.localizedDescription])
            print("Error: \(error)")
        }
    }
    
    // Creates and returns an NSImage from given images
    static func createGIF(with images: [NSImage], loops: Int = GIFHandler.defaultLoops, secondsPrFrame: Float = GIFHandler.defaultFrameDuration) -> NSImage? {
        // Get data and convert to image
        let data = GIFHandler.createGIFData(with: images, loops: loops, secondsPrFrame: secondsPrFrame)
        let img = NSImage(data: data)
        return img
    }
    
    // Creates NSData from given images
    static func createGIFData(with images: [NSImage], loops: Int = GIFHandler.defaultLoops, secondsPrFrame: Float = GIFHandler.defaultFrameDuration) -> Data {
        // Loop count and frame duration
        let frameDurationDic = NSDictionary(dictionary: [kCGImagePropertyGIFDictionary:NSDictionary(dictionary: [kCGImagePropertyGIFDelayTime: secondsPrFrame])])
        let loopCountDic = NSDictionary(dictionary: [kCGImagePropertyGIFDictionary:NSDictionary(dictionary: [kCGImagePropertyGIFLoopCount: loops])])
        
        // Watermark?
        var saveImages:[NSImage] = images
        if UserDefaults.standard.value(forKey: "Watermark") == nil || UserDefaults.standard.value(forKey: "Watermark") as! Bool == true {
            // Comment this line to avoid watermarks
            //saveImages = GIFHandler.addWatermark(images: images)
        }
        
        // Destination (A data object)
        guard let dataObj = CFDataCreateMutable(nil, 0),
              let dst = CGImageDestinationCreateWithData(dataObj, kUTTypeGIF, saveImages.count, nil) else { fatalError("Can't create gif") }
        CGImageDestinationSetProperties(dst, loopCountDic as CFDictionary) // Set loop count on object
        
        // Iterate given images and add these to destination
        for n in 0 ..< saveImages.count {
            let anImage = saveImages[n]
            if let imageRef = anImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                CGImageDestinationAddImage(dst, imageRef, frameDurationDic as CFDictionary)
            }
        }
        
        // Close, cast as data and return
        let _ = CGImageDestinationFinalize(dst)
        let retData = dataObj as Data
        return retData
    }
    
    
    // MARK: Helper functions for gifs
    static func isAnimatedGIF(_ image: NSImage) -> Bool {
        // Attempt to fetch the number of frames, frame duration, and loop count from the .gif
        guard let bitmapRep = image.representations[0] as? NSBitmapImageRep,
            let frameCount = (bitmapRep.value(forProperty: NSImageFrameCount) as? NSNumber)?.intValue,
            let _ = (bitmapRep.value(forProperty: NSImageLoopCount) as? NSNumber)?.intValue,
            let _ = (bitmapRep.value(forProperty: NSImageCurrentFrameDuration) as? NSNumber)?.floatValue else {
            return false
        }

        if frameCount > 1 { // We have loops, duration and everything, and there's more than 1 frame, it's probably a gif
            return true
        }
        
        return false
    }
    
    
    // Adds a watermark to all images in the gif
    static func addWatermark(images: [NSImage]) -> [NSImage] {
        guard let font = NSFont(name: "Helvetica", size: 14) else { return images }
        var returnImages:[NSImage] = []
        
        let string:NSString = "Smart GIF Maker"
        let attrs:[String:Any] = [NSForegroundColorAttributeName: NSColor.white, NSFontAttributeName: font, NSStrokeWidthAttributeName: -3, NSStrokeColorAttributeName: NSColor.black]
        
        for image in images {
            // We need to create a 'copy' of the imagerep, as we need 'isPlanar' to be false in order to draw on it
            // Thanks http://stackoverflow.com/a/13617013
            let tmpRep = NSBitmapImageRep(data: image.tiffRepresentation!)!
            let imgRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                          pixelsWide: tmpRep.pixelsWide,
                                          pixelsHigh: tmpRep.pixelsHigh,
                                          bitsPerSample: tmpRep.bitsPerSample,
                                          samplesPerPixel: tmpRep.samplesPerPixel,
                                          hasAlpha: true,
                                          isPlanar: false,
                                          colorSpaceName: NSDeviceRGBColorSpace,
                                          bitmapFormat: NSAlphaFirstBitmapFormat,
                                          bytesPerRow: tmpRep.bytesPerRow,
                                          bitsPerPixel: tmpRep.bitsPerPixel)
            
            
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.setCurrent(NSGraphicsContext.init(bitmapImageRep: imgRep!))
            
            // Draw image
            image.draw(at: NSPoint.zero, from: NSZeroRect, operation: .copy, fraction: 1.0)
            
            // Draw string
            string.draw(at: NSPoint(x: 5, y: 5), withAttributes: attrs)
            
            NSGraphicsContext.restoreGraphicsState()
            
            let data = imgRep?.representation(using: .GIF, properties: [:])
            let newImg = NSImage(data: data!)
            returnImages.append(newImg!)
        }
        
        return returnImages
    }
}
