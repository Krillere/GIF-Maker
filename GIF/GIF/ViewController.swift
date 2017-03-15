//
//  ViewController.swift
//  GIF
//
//  Created by Christian Lundtofte on 14/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var imageCollectionView:NSCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        /*if let image = NSImage(contentsOfFile: Bundle.main.path(forResource: "banana", ofType: "gif")!),
            let tmp = NSImage(contentsOfFile: Bundle.main.path(forResource: "banana1", ofType: "gif")!) {
            
            let gif = GIFHandler(gif: image)
            gif.pushFrame(frame: tmp)
        }*/
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

// MARK: NSCollectionView
extension ViewController: NSCollectionViewDelegate, NSCollectionViewDataSource {
    fileprivate func configureCollectionView() {
        
        let flowLayout = NSCollectionViewFlowLayout()a
        flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        flowLayout.sectionInset = EdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        imageCollectionView.collectionViewLayout = flowLayout
        
        view.wantsLayer = true
        
        imageCollectionView.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "FrameCollectionViewItem", for: indexPath)
        guard let frameCollectionViewItem = item as? FrameCollectionViewItem else { print("NO"); return item}
        
        return item
    }

    
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    
}
