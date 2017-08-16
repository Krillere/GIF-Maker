//
//  LoadingView.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 16/08/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class LoadingView: NSView {
    
    @IBOutlet var imageView:NSImageView!

    override func draw(_ dirtyRect: NSRect) {
        
        // Image
        let img = NSImage(named: "loading.gif")
        self.imageView.canDrawSubviewsIntoLayer = true
        self.imageView.animates = true
        self.imageView.image = img
        
        self.wantsLayer = true
        
        super.draw(dirtyRect) // Draw
        
        // Background
//        self.alphaValue = 0.7
//        let col:CGFloat = 85.0/255.0
        Constants.darkBackgroundColor.set()
        NSRectFill(self.bounds)
    }
 
}
