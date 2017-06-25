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
        //NotificationCenter.default.post(name: ViewController.imageChangedNotificationName, object: self)
    }
    
    override func mouseDown(with event: NSEvent) {
        
    }

    override func mouseUp(with event: NSEvent) {
        self.delegate?.imageClicked(imageView: self)
//        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: ViewController.imageClickedNotificationName, object: self)
//        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    
}
