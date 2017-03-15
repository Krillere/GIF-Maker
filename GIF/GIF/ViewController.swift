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
    @IBOutlet var addFrameButton:NSButton!
    @IBOutlet var loopsTextField:NSTextField!
    
    var currentImages:[NSImage?] = [nil] // Default is 1 empty image, to show something in UI
    var selectedRow:IndexPath? = nil

    
    // MARK: View setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        
        // Listeners
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.removeFrameCalled(sender:)),
                                               name: NSNotification.Name(rawValue: "RemoveFrame"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.clickedImageView(sender:)),
                                               name: NSNotification.Name(rawValue: "ImageClicked"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.imageDraggedToImageView(sender:)),
                                               name: NSNotification.Name(rawValue: "ImageChanged"), object: nil)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        addFrameButton.becomeFirstResponder()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: UI
    // Adds a new frame
    @IBAction func addFrameButtonClicked(sender: AnyObject?) {
        if let indexPath = selectedRow {
            currentImages.insert(nil, at: indexPath.item+1)
        }
        else {
            currentImages.append(nil)
        }

        imageCollectionView.reloadData()
    }
    
    // A frame wants to be removed (Get index of sender, and remove from 'currentImages')
    func removeFrameCalled(sender: NSNotification) {
        guard let object = sender.object as? FrameCollectionViewItem else { return }
        
        // Remove the index and reload everything
        let index = object.itemIndex
        currentImages.remove(at: index)
        
        imageCollectionView.reloadData()
    }

    // An image was dragged to an imageView
    // Replace the image at the views location to the new one
    func imageDraggedToImageView(sender: NSNotification) {
        guard let imgView = sender.object as? DragNotificationImageView,
              let owner = imgView.ownerCollectionViewItem,
              let img = imgView.image else { return }
        
        currentImages[owner.itemIndex] = img
        self.imageCollectionView.reloadData()
    }
    
    // An ImageView was clicked
    // Show an open dialog and insert image in view and 'currentImages'
    func clickedImageView(sender: NSNotification) {
        guard let imgView = sender.object as? DragNotificationImageView,
              let owner = imgView.ownerCollectionViewItem else { return }
        
        // Show panel
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "gif", "tiff"]
        panel.beginSheetModal(for: self.view.window!) { (response) -> Void in
            
            // Insert image into imageview and 'currentImages' and reload
            if response == NSFileHandlingPanelOKButton {
                let URL = panel.url
                if URL != nil {
                    let image = NSImage(contentsOf: URL!)
                    self.currentImages[owner.itemIndex] = image
                    self.imageCollectionView.reloadData()
                }
            }
            
            imgView.resignFirstResponder()
            self.addFrameButton.becomeFirstResponder()
        }
    }
}

// MARK: NSCollectionView
extension ViewController: NSCollectionViewDelegate, NSCollectionViewDataSource {
    
    // Sets up the collection view variables (Could probably be done in IB)
    // https://www.raywenderlich.com/145978/nscollectionview-tutorial
    fileprivate func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 200.0, height: 220.0)
        flowLayout.sectionInset = EdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        imageCollectionView.collectionViewLayout = flowLayout
        
        view.wantsLayer = true
        
    }
    
    
    // MARK: General delegate / datasource (num items and items themselves)
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "FrameCollectionViewItem", for: indexPath)
        
        // Cast to FrameCollectionView, set index and reset image (To remove old index image)
        guard let frameCollectionViewItem = item as? FrameCollectionViewItem else { print("NO"); return item}
        frameCollectionViewItem.setFrameNumber(indexPath.item+1)
        frameCollectionViewItem.itemIndex = indexPath.item
        frameCollectionViewItem.resetImage()
        
        // If we have an image, insert it here
        if let img = currentImages[indexPath.item] {
            frameCollectionViewItem.setImage(img)
        }
        
        return item
    }

    
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentImages.count
    }
    
    
    // Selection
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        collectionView.deselectAll(nil)
        
        for indexPath in indexPaths {
            guard let item = collectionView.item(at: indexPath) as? FrameCollectionViewItem else {continue}
            
            selectedRow = indexPath
            item.setHighlight(selected: true)
            
            break
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        selectedRow = nil
        collectionView.deselectAll(nil)
    }

    // MARK: Drag and drop
}
