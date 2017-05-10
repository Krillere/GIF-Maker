//
//  FrameCollectionView.swift
//  GIF
//
//  Created by Christian Lundtofte on 15/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class FrameCollectionViewItem: NSCollectionViewItem {
    var itemIndex = -1

    // MARK: NSCollectionViewItem init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.cornerRadius = 5
        view.layer?.borderColor = NSColor.selectedControlColor.cgColor
    }
    
    func setHighlight(selected: Bool) {
        if selected {
            view.layer?.borderWidth = 5.0
        }
        else {
            view.layer?.borderWidth = 0.0
        }
    }
    
    override func keyDown(with event: NSEvent) {
        print("KeyDown!")
    }
    
    // MARK: Image handling
    func setFrameNumber(_ n: Int) {
        self.textField?.stringValue = "Frame "+String(n)
    }
    
    @IBAction func removeMe(sender: AnyObject?) {
        NotificationCenter.default.post(name: ViewController.removeFrameNotificationName, object: self)
    }
    
    func setImage(_ img: NSImage) {
        if let imgView = self.imageView as? DragNotificationImageView {
            imgView.image = img
        }
    }
    
    func resetImage() {
        if let imgView = self.imageView as? DragNotificationImageView {
            imgView.image = nil
        }
    }
}
