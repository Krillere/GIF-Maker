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
    
    // MARK: Setup
    override func awakeFromNib() {
        super.awakeFromNib()
        self.register(forDraggedTypes: NSImage.imageTypes())
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    
    // MARK: Drag
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        self.delegate?.imageDragged(imageView: self)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    
    // MARK: Mouse
    override func mouseDown(with event: NSEvent) {
    }

    override func mouseUp(with event: NSEvent) {
        self.delegate?.imageClicked(imageView: self)
    }

    
    
}
