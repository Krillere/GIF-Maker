//
//  FancyAlert.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 17/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class FancyAlert: NSAlert {
    override func awakeFromNib() {
        if let contentView = self.window.contentView {
            self.window.contentView?.backgroundColor = ViewController.backgroundColor
        
            // Modify or find subviews to be changed
            contentView.subviews.forEach({ (subview) in
                if subview is NSTextField {
                    (subview as! NSTextField).textColor = NSColor.white
                }
            })
        }
    }
}
