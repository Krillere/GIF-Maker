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
    var previewImage:NSImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.backgroundColor = Constants.darkBackgroundColor
        
        // Load image or dismiss preview
        if let previewImage = previewImage {
            previewImageView.image = previewImage
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
