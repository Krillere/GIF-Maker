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
    var duration:Double = GIFHandler.defaultFrameDuration
    
    static let emptyFrame:GIFFrame = GIFFrame()
    
    init(image: NSImage, duration: Double = GIFHandler.defaultFrameDuration) {
        self.image = image
        self.duration = duration
    }
    
    init() { }
}
