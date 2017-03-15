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
    @IBOutlet var secondsPerFrameTextField:NSTextField!
    
    var currentImages:[NSImage?] = [nil] // Default is 1 empty image, to show something in UI
    
    // MARK: View setup
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

    // MARK: UI
    @IBAction func addFrameButtonClicked(sender: AnyObject?) {
        currentImages.append(nil)
        imageCollectionView.reloadData()
    }

}

// MARK: NSCollectionView
extension ViewController: NSCollectionViewDelegate, NSCollectionViewDataSource {
    fileprivate func configureCollectionView() {
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 200.0, height: 220.0)
        flowLayout.sectionInset = EdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        imageCollectionView.collectionViewLayout = flowLayout
        
        view.wantsLayer = true
        
    }
    
    
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "FrameCollectionViewItem", for: indexPath)
        
        guard let frameCollectionViewItem = item as? FrameCollectionViewItem else { print("NO"); return item}
        frameCollectionViewItem.setFrameNumber(indexPath.item+1)
        
        return item
    }

    
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentImages.count
    }
    
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    
}
