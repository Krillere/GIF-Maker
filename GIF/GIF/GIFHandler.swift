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
    static func loadGIF(with image: NSImage) -> (images: [NSImage], loops:Int, secondsPrFrame: Float) {
        let errorReturn:(images: [NSImage], loops:Int, secondsPrFrame: Float) = (images: [], loops: 0, secondsPrFrame: 0.2)
        
        guard let bitmapRep = image.representations[0] as? NSBitmapImageRep,
              let frameCount = (bitmapRep.value(forProperty: NSImageFrameCount) as? NSNumber)?.intValue,
              let frameDuration = (bitmapRep.value(forProperty: NSImageCurrentFrameDuration) as? NSNumber)?.floatValue,
              let loopCount = (bitmapRep.value(forProperty: NSImageLoopCount) as? NSNumber)?.intValue else { return errorReturn }
        
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
        // Loop count and seconds pr. frame
        let prep = NSDictionary(dictionary: [kCGImagePropertyGIFDictionary:NSDictionary(dictionary: [kCGImagePropertyGIFDelayTime: secondsPrFrame, kCGImagePropertyGIFLoopCount: loops])])
        
        // Destination (A data object)
        guard let dataObj = CFDataCreateMutable(nil, 0),
            let dst = CGImageDestinationCreateWithData(dataObj, kUTTypeGIF, images.count, nil) else { fatalError("Can't create gif") }

        // Iterate given images and add these to destination
        for n in 0 ..< images.count {
            let anImage = images[n]
            if let imageRef = anImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                CGImageDestinationAddImage(dst, imageRef, prep as CFDictionary)
            }
        }
        
        // Close, cast as data and return
        let _ = CGImageDestinationFinalize(dst)
        let retData = dataObj as Data
        return retData
    }
}
