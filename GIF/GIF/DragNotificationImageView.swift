//
//  DragNotificationImageView.swift
//  SwiftImageResizer
//
//  Created by Christian on 07/01/2016.
//  Copyright © 2016 Christian Lundtofte Sørensen. All rights reserved.
//

import Cocoa

class DragNotificationImageView: NSImageView {
    @IBOutlet var ownerCollectionViewItem:FrameCollectionViewItem!
    var gifFrame: GIFFrame?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        NotificationCenter.default.post(name: ViewController.imageChangedNotificationName, object: self)
    }
    
    override func mouseDown(with event: NSEvent) {
        
    }

    override func mouseUp(with event: NSEvent) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: ViewController.imageClickedNotificationName, object: self)
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    
}
