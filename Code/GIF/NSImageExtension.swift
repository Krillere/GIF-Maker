//
//  NSImageExtension.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 16/08/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {
    
    // Used for converting anything else to NSBitmapImageRep
    // Based on https://stackoverflow.com/a/34555866
    func unscaledBitmapImageRep() -> NSBitmapImageRep {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(self.size.width),
            pixelsHigh: Int(self.size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSCalibratedRGBColorSpace,
            bytesPerRow: 0,
            bitsPerPixel: 0
            ) else {
                preconditionFailure()
        }
 
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrent(NSGraphicsContext(bitmapImageRep: rep))
        self.draw(at: NSZeroPoint, from: NSZeroRect, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
 
        return rep
    }
    
    func getBitmapRep() -> NSBitmapImageRep? {
        for rep in self.representations {
            if let tmpRep = rep as? NSBitmapImageRep {
                return tmpRep
            }
        }

        return self.unscaledBitmapImageRep()
    }
}
