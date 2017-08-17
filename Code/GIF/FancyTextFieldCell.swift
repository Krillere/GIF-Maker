//
//  FancyTextFieldCell.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 15/08/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

// From https://stackoverflow.com/a/40065608
class FancyTextFieldCell: NSTextFieldCell {
    @IBInspectable var borderColor: NSColor = .clear
    @IBInspectable var cornerRadius: CGFloat = 3
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        let bounds = NSBezierPath(roundedRect: cellFrame, xRadius: cornerRadius, yRadius: cornerRadius)
        bounds.addClip()
        
        super.draw(withFrame: cellFrame, in: controlView)
        
        if borderColor != .clear {
            bounds.lineWidth = 2
            borderColor.setStroke()
            bounds.stroke()
        }
    }
}
