//
//  PreviewViewController.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 16/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class PreviewViewController: NSViewController {
    @IBOutlet var previewImageView:NSImageView!
    var previewImagePath:URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.backgroundColor = Constants.darkBackgroundColor
        
        // Load image or dismiss preview
        if let previewImagePath = self.previewImagePath {
            self.previewImageView.canDrawSubviewsIntoLayer = true
//            self.previewImageView.imageScaling = .scaleProportionallyDown
            self.previewImageView.animates = true
            self.previewImageView.image = NSImage(contentsOf: previewImagePath)
        }
        else {
            self.dismiss(self)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.wantsLayer = true
        self.view.backgroundColor = Constants.darkBackgroundColor
        
        
    }
    
    @IBAction func closeButtonClicked(sender: AnyObject?) {
        self.dismiss(self)
    }
}
