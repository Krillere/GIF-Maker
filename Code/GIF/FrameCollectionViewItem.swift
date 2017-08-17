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
    func frameDurationChanged(item: FrameCollectionViewItem)
}

class FrameCollectionViewItem: NSCollectionViewItem, DragNotificationImageViewDelegate {
    var itemIndex = -1
    var delegate:FrameCollectionViewItemDelegate?
    
    @IBOutlet var durationTextField:SmartTextField!

    // MARK: NSCollectionViewItem init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.cornerRadius = 10
        view.layer?.borderColor = NSColor.selectedControlColor.cgColor
        
        self.durationTextField.stringValue = String(format: "%.3lf", GIFHandler.defaultFrameDuration)
        
        if let imgView = self.imageView as? DragNotificationImageView {
            imgView.delegate = self
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Set duration if known
        if let imgView = self.imageView as? DragNotificationImageView,
            let frame = imgView.gifFrame {
            self.durationTextField.stringValue = String(format: "%.3lf", frame.duration)
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
    override func controlTextDidChange(_ obj: Notification) {
        if let field = obj.object as? NSTextField {
            if field == self.durationTextField {
                if var val = Double(self.durationTextField.stringValue) {
                    if val < GIFHandler.minFrameDuration {
                        val = GIFHandler.minFrameDuration
                    }
                    
                    self.delegate?.frameDurationChanged(item: self)
                }
                else {
                    self.durationTextField.stringValue = String(format: "%.3lf", GIFHandler.defaultFrameDuration)
                }
            }
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        if let field = obj.object as? NSTextField {
            if field == self.durationTextField {
                if var val = Double(self.durationTextField.stringValue) {
                    if val < GIFHandler.minFrameDuration {
                        val = GIFHandler.minFrameDuration
                    }
                    
                    self.delegate?.frameDurationChanged(item: self)
                    self.durationTextField.stringValue = String(format: "%.3lf", val)
                }
                else {
                    
                }
            }
        }
    }
    
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
        self.delegate?.frameImageChanged(item: self)
    }
    
    func imageClicked(imageView: DragNotificationImageView) {
        self.delegate?.frameImageClicked(item: self)
    }
}
