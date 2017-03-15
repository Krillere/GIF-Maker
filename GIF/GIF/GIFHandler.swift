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
    private var numLoops = 0
    private var frameTime = 0.2
    private var frames:[NSImage] = []
    
    /*
     var filesArray:[NSImage] = []
     guard let img1 = NSImage(contentsOfFile: Bundle.main.path(forResource: "banana1", ofType: "gif")!),
     let img2 = NSImage(contentsOfFile: Bundle.main.path(forResource: "banana2", ofType: "gif")!) else { return }
     filesArray.append(img1)
     filesArray.append(img2) //.representations[0] as! NSBitmapImageRep
     
     let prep = NSDictionary(dictionary: [kCGImagePropertyGIFDictionary:NSDictionary(dictionary: [kCGImagePropertyGIFDelayTime: 0.2])])
     
     guard let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: "/Users/Christian/Desktop/test.gif") as CFURL, kUTTypeGIF, filesArray.count, nil) else { return }
     
     for n in 0 ..< filesArray.count {
     var anImage = filesArray[n]
     if var imageRef = anImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
     CGImageDestinationAddImage(dst, imageRef, prep as CFDictionary)
     }
     }
     
     var fileSave = CGImageDestinationFinalize(dst)
     */
    
    func getFrameCount() -> Int {
        return frames.count
    }
    
    func getFrames() -> [NSImage] {
        return frames
    }
    
    func getFrame(at: Int) -> NSImage {
        return frames[at]
    }
 
    
    // MARK: Making gifs from iamges
    // Creates and saves a gif
    static func createAndSaveGIF(with images: [NSImage], savePath: URL, loops: Int = 0, secondsPrFrame: Float = 0.2) {
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
        let data = GIFHandler.createGIFData(with: images, loops: loops, secondsPrFrame: secondsPrFrame)
        let img = NSImage(data: data)
        return img
    }
    
    // Creates NSData from given images
    static func createGIFData(with images: [NSImage], loops: Int = 0, secondsPrFrame: Float = 0.2) -> Data {
        // Loop count and seconds pr. frame
        let prep = NSDictionary(dictionary: [kCGImagePropertyGIFDictionary:NSDictionary(dictionary: [kCGImagePropertyGIFDelayTime: secondsPrFrame, kCGImagePropertyGIFLoopCount: loops])])
        
        // Destination
        guard let dataObj = CFDataCreateMutable(nil, 0),
            let dst = CGImageDestinationCreateWithData(dataObj, kUTTypeGIF, images.count, nil) else { fatalError("Can't create gif") }
        //guard let dst = CGImageDestinationCreateWithURL(savePath as CFURL, kUTTypeGIF, images.count, nil) else { return }
        
        for n in 0 ..< images.count {
            let anImage = images[n]
            if let imageRef = anImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                CGImageDestinationAddImage(dst, imageRef, prep as CFDictionary)
            }
        }
        
        let _ = CGImageDestinationFinalize(dst)
        let retData = dataObj as Data
        return retData
    }
}
