//
//  File.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 13/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Foundation
import Cocoa

extension NSView {
    
    // http://stackoverflow.com/a/31461380
    var backgroundColor: NSColor? {
        get {
            if let colorRef = self.layer?.backgroundColor {
                return NSColor(cgColor: colorRef)
            }
            else {
                return nil
            }
        }
        set {
            self.wantsLayer = true
            self.layer?.backgroundColor = newValue?.cgColor
        }
    }
    
    func center(inView: NSView) {
        self.setFrameOrigin(NSMakePoint(
            (NSWidth(inView.bounds) - NSWidth(self.frame)) / 2,
            (NSHeight(inView.bounds) - NSHeight(self.frame)) / 2
        ));
    }
}
