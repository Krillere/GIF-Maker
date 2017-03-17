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

    // MARK: Loading gifs (Returns tuple with images, loop count and seconds/frame
    static func loadGIF(with image: NSImage) -> (images: [NSImage?], loops:Int, secondsPrFrame: Float) {
        let errorReturn:(images: [NSImage?], loops:Int, secondsPrFrame: Float) = (images: [nil], loops: 0, secondsPrFrame: 0.2)
        
        // Attempt to fetch the number of frames, frame duration, and loop count from the .gif
        guard let bitmapRep = image.representations[0] as? NSBitmapImageRep else {
            print("Error loading bitmapRep")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GIFError"), object: self, userInfo: ["Error":"Could not load gif"])
            return errorReturn
        }
        guard let frameCount = (bitmapRep.value(forProperty: NSImageFrameCount) as? NSNumber)?.intValue else {
            print("Error loading frameCount")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GIFError"), object: self, userInfo: ["Error":"Could not load gif"])
            return errorReturn
        }
        guard let frameDuration = (bitmapRep.value(forProperty: NSImageCurrentFrameDuration) as? NSNumber)?.floatValue else {
            print("Error loading frameDuration")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GIFError"), object: self, userInfo: ["Error":"Could not load gif"])
            return errorReturn
        }
        guard let loopCount = (bitmapRep.value(forProperty: NSImageLoopCount) as? NSNumber)?.intValue else {
            print("Error loading loopCount")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GIFError"), object: self, userInfo: ["Error":"Could not load gif"])
            return errorReturn
        }
        
        var retImages:[NSImage] = []
        
        // Iterate the frames, set the current frame on the bitmapRep and add this to 'retImages'
        for n in 0 ..< frameCount {
            bitmapRep.setProperty(NSImageCurrentFrame, withValue: NSNumber(value: n))
            
            if let data = bitmapRep.representation(using: .GIF, properties: [:]),
               let img = NSImage(data: data) {
                retImages.append(img)
            }
        }
        
        return (images: retImages, loops: loopCount, secondsPrFrame: frameDuration)
    }
    
    
    // MARK: Making gifs from iamges
    // Creates and saves a gif
    static func createAndSaveGIF(with images: [NSImage], savePath: URL, loops: Int = 0, secondsPrFrame: Float = 0.2) {
        // Get and save data at 'savePath'
        let data = GIFHandler.createGIFData(with: images, loops: loops, secondsPrFrame: secondsPrFrame)
        
        do {
            try data.write(to: savePath)
        }
        catch {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GIFError"), object: self, userInfo: ["Error":"Could not save file: "+error.localizedDescription])
            print("Error: \(error)")
        }
    }
    
    // Creates and returns an NSImage from given images
    static func createGIF(with images: [NSImage], loops: Int = 0, secondsPrFrame: Float = 0.2) -> NSImage? {
        // Get data and convert to image
        let data = GIFHandler.createGIFData(with: images, loops: loops, secondsPrFrame: secondsPrFrame)
        let img = NSImage(data: data)
        return img
    }
    
    // Creates NSData from given images
    static func createGIFData(with images: [NSImage], loops: Int = 0, secondsPrFrame: Float = 0.2) -> Data {
        // Loop count and frame duration
        let frameDurationDic = NSDictionary(dictionary: [kCGImagePropertyGIFDictionary:NSDictionary(dictionary: [kCGImagePropertyGIFDelayTime: secondsPrFrame])])
        let loopCountDic = NSDictionary(dictionary: [kCGImagePropertyGIFDictionary:NSDictionary(dictionary: [kCGImagePropertyGIFLoopCount: loops])])
        
        // Destination (A data object)
        guard let dataObj = CFDataCreateMutable(nil, 0),
              let dst = CGImageDestinationCreateWithData(dataObj, kUTTypeGIF, images.count, nil) else { fatalError("Can't create gif") }
        CGImageDestinationSetProperties(dst, loopCountDic as CFDictionary) // Set loop count on object
        
        // Iterate given images and add these to destination
        for n in 0 ..< images.count {
            let anImage = images[n]
            if let imageRef = anImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                CGImageDestinationAddImage(dst, imageRef, frameDurationDic as CFDictionary)
            }
        }
        
        // Close, cast as data and return
        let _ = CGImageDestinationFinalize(dst)
        let retData = dataObj as Data
        return retData
    }
}
