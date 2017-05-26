//
//  FancyButton.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 15/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class FancyButton: NSButton {
    let textColor = NSColor.white

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func awakeFromNib() {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attrs = [NSForegroundColorAttributeName: self.textColor, NSParagraphStyleAttributeName: style]
        let attrString = NSAttributedString(string: self.title, attributes: attrs)
        self.attributedTitle = attrString
        
        self.focusRingType = .none
        
        // Mouse in / out
        let area = NSTrackingArea.init(rect: self.bounds, options: [NSTrackingAreaOptions.mouseEnteredAndExited, NSTrackingAreaOptions.activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(area)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let cell = self.cell as? FancyButtonCell {
            cell.mouseOver = true
            cell.redraw()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if let cell = self.cell as? FancyButtonCell {
            cell.mouseOver = false
            cell.redraw()
        }
    }
}
