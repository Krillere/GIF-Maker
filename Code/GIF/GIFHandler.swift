//
//  GIFHandler.swift
//  GIF
//
//  Created by Christian Lundtofte on 14/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Foundation
import AVFoundation
import Cocoa

// Replaces the old '(frames: [GIFFrame], loops:Int, secondsPrFrame: Float)' with a type
// Describes the data necessary to show a gif. Frames, loops, and duration
class GIFRepresentation {
    var frames:[GIFFrame] = [GIFFrame.emptyFrame]
    var loops:Int = GIFHandler.defaultLoops
    
    init(frames: [GIFFrame], loops:Int) {
        self.frames = frames
        self.loops = loops
    }
    
    init() {}
}

// Creates and loads gifs
class GIFHandler {

    // MARK: Constants
    static let errorNotificationName = NSNotification.Name(rawValue: "GIFError")
    static let defaultLoops:Int = 0
    static let defaultFrameDuration:Double = 0.2
    
    // MARK: Loading gifs
    static func loadGIF(with image: NSImage, onFinish: ((GIFRepresentation) -> ())) {
        
        // Attempt to fetch the number of frames, frame duration, and loop count from the .gif
        guard let bitmapRep = image.representations[0] as? NSBitmapImageRep,
            let frameCount = (bitmapRep.value(forProperty: NSImageFrameCount) as? NSNumber)?.intValue,
            let loopCount = (bitmapRep.value(forProperty: NSImageLoopCount) as? NSNumber)?.intValue else {
                
            NotificationCenter.default.post(name: errorNotificationName, object: self, userInfo: ["Error":"Could not load gif. The file does not contain the metadata required for a gif."])
            onFinish(GIFRepresentation())
            return
        }

        
        var retFrames:[GIFFrame] = []
        
        // Iterate the frames, set the current frame on the bitmapRep and add this to 'retImages'
        for n in 0 ..< frameCount {
            bitmapRep.setProperty(NSImageCurrentFrame, withValue: NSNumber(value: n))
            
            if let data = bitmapRep.representation(using: .GIF, properties: [:]),
               let img = NSImage(data: data) {
                let frame = GIFFrame(image: img)
                
                if let frameDuration = (bitmapRep.value(forProperty: NSImageCurrentFrameDuration) as? NSNumber)?.doubleValue {
                    frame.duration = frameDuration
                }
                
                retFrames.append(frame)
            }
        }
        
        onFinish(GIFRepresentation(frames: retFrames, loops: loopCount))
    }
    
    // MARK: Loading video files
    static func loadVideo(with path: URL, withFPS: Float64 = 5, onFinish: ((GIFRepresentation) -> ())) {
        let videoRepresentation = GIFRepresentation(frames: [], loops: 0)
        
        // Read video
        let asset = AVURLAsset(url: path)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceAfter = kCMTimeZero
        generator.requestedTimeToleranceBefore = kCMTimeZero
        
        // Find frames and setup variables
        var curFrame:Float64 = 0
        let duration = CMTimeGetSeconds(asset.duration)
        let frames = duration * withFPS
        while curFrame < frames { // Find images
            let time = CMTimeMake(Int64(curFrame), Int32(withFPS))
            var actualTime:CMTime = CMTime()
            
            do {
                let cgimg = try generator.copyCGImage(at: time, actualTime: &actualTime)
                let tmpImg = NSImage(cgImage: cgimg, size: NSSize(width: cgimg.width, height: cgimg.height))
                
                // Remove representations, and add NSBitmapImageRep (Used for modifying when editing)
                let img = NSImage()
                img.addRepresentation(img.unscaledBitmapImageRep())
                
                videoRepresentation.frames.append(GIFFrame(image: img, duration: (duration/withFPS)/100))
            }
            catch {
                print("Exception during MP4 load.")
                NotificationCenter.default.post(name: errorNotificationName, object: self, userInfo: ["Error":"Error loading frame in video."])
                onFinish(videoRepresentation)
                return
            }
            
            curFrame += 1
        }
        
        onFinish(videoRepresentation)
    }
    
    // MARK: Making gifs from iamges
    // Creates and saves a gif
    static func createAndSaveGIF(with frames: [GIFFrame], savePath: URL, loops: Int = GIFHandler.defaultLoops) {
        // Get and save data at 'savePath'
        let data = GIFHandler.createGIFData(with: frames, loops: loops)
        
        do {
            try data.write(to: savePath)
        }
        catch {
            NotificationCenter.default.post(name: errorNotificationName, object: self, userInfo: ["Error":"Could not save file: "+error.localizedDescription])
            print("Error: \(error)")
        }
    }
    
    // Creates and returns an NSImage from given images
    static func createGIF(with frames: [GIFFrame], loops: Int = GIFHandler.defaultLoops) -> NSImage? {
        // Get data and convert to image
        let data = GIFHandler.createGIFData(with: frames, loops: loops)
        let img = NSImage(data: data)
        return img
    }
    
    // Creates NSData from given images
    static func createGIFData(with frames: [GIFFrame], loops: Int = GIFHandler.defaultLoops) -> Data {
        // Loop count
        let loopCountDic = NSDictionary(dictionary: [kCGImagePropertyGIFDictionary:NSDictionary(dictionary: [kCGImagePropertyGIFLoopCount: loops])])
        
        // Number of frames
        let imageCount = frames.filter { (frame) -> Bool in
            return frame.image != nil
        }.count
        
        // Destination (Data object)
        guard let dataObj = CFDataCreateMutable(nil, 0),
            let dst = CGImageDestinationCreateWithData(dataObj, kUTTypeGIF, imageCount, nil) else { fatalError("Can't create gif") }
        CGImageDestinationSetProperties(dst, loopCountDic as CFDictionary) // Set loop count on object
        
        // Add images to destination
        frames.forEach { (frame) in
            guard var image = frame.image else { return }
//            if !Products.store.isProductPurchased(Products.Pro) {
//                // Watermark
//                image = GIFHandler.addWatermark(image: image, watermark: "Smart GIF Maker")
//            }
            
            if let imageRef = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                // Frame duration
                let frameDurationDic = NSDictionary(dictionary: [kCGImagePropertyGIFDictionary:NSDictionary(dictionary: [kCGImagePropertyGIFDelayTime: frame.duration])])
                
                // Add image
                CGImageDestinationAddImage(dst, imageRef, frameDurationDic as CFDictionary)
            }
        }
        

        // Close, cast as data and return
        let _ = CGImageDestinationFinalize(dst)
        let retData = dataObj as Data
        return retData
    }
    
    
    // MARK: Helper functions for gifs
    // Naive method for determining whether something is an animated gif
    static func isAnimatedGIF(_ image: NSImage) -> Bool {
        // Attempt to fetch the number of frames, frame duration, and loop count from the .gif
        guard let bitmapRep = image.representations[0] as? NSBitmapImageRep,
            let frameCount = (bitmapRep.value(forProperty: NSImageFrameCount) as? NSNumber)?.intValue,
            let _ = (bitmapRep.value(forProperty: NSImageLoopCount) as? NSNumber)?.intValue,
            let _ = (bitmapRep.value(forProperty: NSImageCurrentFrameDuration) as? NSNumber)?.floatValue else {
            return false
        }

        return frameCount > 1 // We have loops, duration and everything, and there's more than 1 frame, it's probably a gif
    }
    
    
    // Adds a watermark to an image
    static func addWatermark(image: NSImage, watermark: String) -> NSImage {
        guard let font = NSFont(name: "Helvetica", size: 14) else { return image }
        
        let attrs:[String:Any] = [NSForegroundColorAttributeName: NSColor.white, NSFontAttributeName: font, NSStrokeWidthAttributeName: -3, NSStrokeColorAttributeName: NSColor.black]
        
        // We need to create a 'copy' of the imagerep, as we need 'isPlanar' to be false in order to draw on it
        // Thanks http://stackoverflow.com/a/13617013 and https://gist.github.com/randomsequence/b9f4462b005d0ced9a6c
        let tmpRep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        guard let imgRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                            pixelsWide: tmpRep.pixelsWide,
                                            pixelsHigh: tmpRep.pixelsHigh,
                                            bitsPerSample: 8,
                                            samplesPerPixel: 4,
                                            hasAlpha: true,
                                            isPlanar: false,
                                            colorSpaceName: NSCalibratedRGBColorSpace,
                                            bytesPerRow: 0,
                                            bitsPerPixel: 0) else { print("Error image"); return image }
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrent(NSGraphicsContext.init(bitmapImageRep: imgRep))
        
        // Draw image and string
        image.draw(at: NSPoint.zero, from: NSZeroRect, operation: .copy, fraction: 1.0)
        watermark.draw(at: NSPoint(x: 5, y: 5), withAttributes: attrs)
        
        NSGraphicsContext.restoreGraphicsState()
        
        let data = imgRep.representation(using: .GIF, properties: [:])
        if let newImg = NSImage(data: data!) {
            return newImg
        }
        
        return image
    }
}
