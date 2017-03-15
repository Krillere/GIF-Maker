//
//  DragNotificationImageView.swift
//  SwiftImageResizer
//
//  Created by Christian on 07/01/2016.
//  Copyright © 2016 Christian Lundtofte Sørensen. All rights reserved.
//

import Cocoa

class DragNotificationImageView: NSImageView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ImageChanged"), object: nil)
    }
    
    override func mouseDown(with event: NSEvent) {
        
    }

    override func mouseUp(with event: NSEvent) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ImageClicked"), object: nil)
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    
}
