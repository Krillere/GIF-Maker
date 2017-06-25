//
//  FancyButton.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 15/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class FancyButtonCell: NSButtonCell {
    var intLineColor:NSColor = NSColor(red: 0.0, green: 139.0/255.0, blue: 1.0, alpha: 1.0)
    var intPushLineColor:NSColor = NSColor(red: 0.0, green: 194.0/255.0, blue: 1.0, alpha: 1.0)
    var mouseOver:Bool = false
    
    @IBInspectable var lineColor: NSColor {
        get {
            return intLineColor
        }
        set {
            intLineColor = newValue
        }
    }
    
    @IBInspectable var pushedLineColor: NSColor {
        get {
            return intPushLineColor
        }
        set {
            intPushLineColor = newValue
        }
    }

    override func awakeFromNib() {
        self.setButtonType(.momentaryChange)
    }
    
    func redraw() {
        self.backgroundColor = self.backgroundColor // lol
    }
    
    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {

        let path = NSBezierPath(roundedRect: frame.insetBy(dx: 0.5, dy: 0.5), xRadius: 3, yRadius: 3)
        path.lineWidth = 2
        
        if !self.mouseOver { // Normal or selected
            if self.isHighlighted {
                intPushLineColor.setStroke()
            }
            else {
                intLineColor.setStroke()
            }
            
            path.stroke()
        }
        else { // Mouse over
            intLineColor.setFill()
            intLineColor.setStroke()
            path.fill()
            path.stroke()
        }
        
    }
}
