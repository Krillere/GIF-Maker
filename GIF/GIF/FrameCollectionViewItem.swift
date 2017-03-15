//
//  FrameCollectionView.swift
//  GIF
//
//  Created by Christian Lundtofte on 15/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class FrameCollectionViewItem: NSCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    func setFrameNumber(_ n: Int) {
        self.textField?.stringValue = "Frame "+String(n)
    }
    
    @IBAction func removeMe(sender: AnyObject?) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RemoveFrame"), object: self)
    }
}
