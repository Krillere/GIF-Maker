
//
//  ZoomView.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 16/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

protocol ZoomViewDelegate {
    func zoomChanged(magnification: CGFloat)
}

class ZoomView: NSView {
    var delegate:ZoomViewDelegate?
    var zoomView:NSView?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    
    var previousZoomSize:NSSize?
    override func magnify(with event: NSEvent) {
        super.magnify(with: event)
        
        guard let zoomView = self.zoomView else { return }
        
        if(event.phase == .changed) {
            var newSize = NSMakeSize(0, 0)
            newSize.width = zoomView.frame.size.width * (event.magnification + 1.0)
            newSize.height = zoomView.frame.size.height * (event.magnification + 1.0)
            zoomView.setFrameSize(newSize)
            previousZoomSize = newSize
            
            self.delegate?.zoomChanged(magnification: event.magnification)
        }
    }
    
    func redoZoom() {
        if let zoom = previousZoomSize {
            zoomView?.setFrameSize(zoom)
            self.delegate?.zoomChanged(magnification: 0.0)
        }
    }
}
