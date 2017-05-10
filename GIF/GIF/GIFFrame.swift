//
//  GIFFrame.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 07/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Foundation
import AppKit

class GIFFrame {
    var image:NSImage?
    var duration:Float = GIFHandler.defaultFrameDuration
    
    init(image: NSImage, duration: Float = GIFHandler.defaultFrameDuration) {
        self.image = image
        self.duration = duration
    }
    
    init() { }
    
    static func emptyFrame() -> GIFFrame {
        return GIFFrame()
    }
}
