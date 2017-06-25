//
//  FrameCollectionView.swift
//  GIF
//
//  Created by Christian Lundtofte on 15/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

protocol FrameCollectionViewItemDelegate {
    func removeFrame(item: FrameCollectionViewItem)
    func editFrame(item: FrameCollectionViewItem)
    
    func frameImageChanged(item: FrameCollectionViewItem)
    func frameImageClicked(item: FrameCollectionViewItem)
}

class FrameCollectionViewItem: NSCollectionViewItem, DragNotificationImageViewDelegate {
    var itemIndex = -1
    var delegate:FrameCollectionViewItemDelegate?

    // MARK: NSCollectionViewItem init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.cornerRadius = 6
        view.layer?.borderColor = NSColor.selectedControlColor.cgColor
        
        if let imgView = self.imageView as? DragNotificationImageView {
            imgView.delegate = self
        }
    }
    
    func setHighlight(selected: Bool) {
        if selected {
            view.layer?.borderWidth = 4.0
        }
        else {
            view.layer?.borderWidth = 0.0
        }
    }
    
    // MARK: UI
    // Sets the frame number
    func setFrameNumber(_ n: Int) {
        self.textField?.stringValue = "Frame "+String(n)
    }
    
    // Removes me
    @IBAction func removeMe(sender: AnyObject?) {
        self.delegate?.removeFrame(item: self)
    }
    
    // Edits me
    @IBAction func editMe(sender: AnyObject?) {
        self.delegate?.editFrame(item: self)
    }
    
    // MARK: Image handling
    // Sets an image
    func setImage(_ img: NSImage) {
        if let imgView = self.imageView as? DragNotificationImageView {
            imgView.image = img
        }
    }
    
    // Resets(removes) an image
    func resetImage() {
        if let imgView = self.imageView as? DragNotificationImageView {
            imgView.image = nil
        }
    }
    
    // MARK: DragNotificationImageViewDelegate
    func imageDragged(imageView: DragNotificationImageView) {
        
    }
    
    func imageClicked(imageView: DragNotificationImageView) {
        
    }
}
