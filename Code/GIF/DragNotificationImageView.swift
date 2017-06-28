//
//  DragNotificationImageView.swift
//  SwiftImageResizer
//
//  Created by Christian on 07/01/2016.
//  Copyright © 2016 Christian Lundtofte Sørensen. All rights reserved.
//

import Cocoa

protocol DragNotificationImageViewDelegate {
    func imageClicked(imageView: DragNotificationImageView)
    func imageDragged(imageView: DragNotificationImageView)
}

class DragNotificationImageView: NSImageView {
    var delegate:DragNotificationImageViewDelegate?
    var gifFrame: GIFFrame?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        self.delegate?.imageDragged(imageView: self)
    }
    
    override func mouseDown(with event: NSEvent) {
        
    }

    override func mouseUp(with event: NSEvent) {
        self.delegate?.imageClicked(imageView: self)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    
}
