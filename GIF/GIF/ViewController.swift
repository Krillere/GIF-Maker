//
//  ViewController.swift
//  GIF
//
//  Created by Christian Lundtofte on 14/03/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    // MARK: Fields
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
        
        // Listeners for events regarding frames and images
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
        if let indexPath = selectedRow { // Add after selectedRow
            currentImages.insert(nil, at: indexPath.item+1)
        }
        else { // Add empty frame
            currentImages.append(nil)
        }

        imageCollectionView.reloadData()
        deselectAll()
    }
    
    // Export a gif
    @IBAction func exportGIFButtonClicked(sender: AnyObject?) {
        guard let loops = Int(loopsTextField.stringValue),
              let spf = Float(secondsPerFrameTextField.stringValue) else {
                print("Nope.")
                return
        }
        
        // Remove empty images
        var tmpImages:[NSImage] = []
        for img in currentImages {
            if let img = img {
                tmpImages.append(img)
            }
        }
        
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["gif"]
        panel.begin { (res) in
            if res == NSFileHandlingPanelOKButton {
                if let url = panel.url {
                    GIFHandler.createAndSaveGIF(with: tmpImages, savePath: url, loops: loops, secondsPrFrame: spf)
                }
            }
        }
        
    }
    
    // Load a gif from a file
    @IBAction func loadGIFButtonClicked(sender: AnyObject?) {
        // SHow file panel
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["gif"]
        panel.allowsMultipleSelection = false
        panel.allowsOtherFileTypes = false
        panel.canChooseDirectories = false
        panel.begin { (res) in
            if res == NSFileHandlingPanelOKButton {
                // Load image from file
                if let url = panel.url,
                   let image = NSImage(contentsOf: url) {
                    // Set values from the .GIF
                    let newValues = GIFHandler.loadGIF(with: image)
                    
                    self.currentImages = newValues.images
                    self.secondsPerFrameTextField.stringValue = String(newValues.secondsPrFrame)
                    self.loopsTextField.stringValue = String(newValues.loops)
                    
                    self.imageCollectionView.reloadData()
                }
            }
        }
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
    
    var indexPathsOfItemsBeingDragged: Set<IndexPath>!
}

// MARK: NSCollectionView
extension ViewController: NSCollectionViewDelegate, NSCollectionViewDataSource {
    
    // Sets up the collection view variables (Could probably be done in IB), and allows drag'n'drop
    // https://www.raywenderlich.com/145978/nscollectionview-tutorial
    // https://www.raywenderlich.com/132268/advanced-collection-views-os-x-tutorial
    fileprivate func configureCollectionView() {
        // Layout
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 200.0, height: 220.0)
        flowLayout.sectionInset = EdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        imageCollectionView.collectionViewLayout = flowLayout
        
        view.wantsLayer = true
        
        // Drag
        var dragTypes = NSImage.imageTypes()
        dragTypes.append(NSURLPboardType)
        imageCollectionView.register(forDraggedTypes: dragTypes)
        imageCollectionView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        imageCollectionView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
    }
    
    // Deselects all items
    func deselectAll() {
        let paths = imageCollectionView.indexPathsForVisibleItems()
        for path in paths {
            if let item = imageCollectionView.item(at: path) as? FrameCollectionViewItem {
                item.setHighlight(selected: false)
            }
        }
    }
    
    // MARK: General delegate / datasource (num items and items themselves)
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "FrameCollectionViewItem", for: indexPath)
        
        // Cast to FrameCollectionView, set index and reset image (To remove old index image)
        guard let frameCollectionViewItem = item as? FrameCollectionViewItem else { print("NO"); return item}
        frameCollectionViewItem.setFrameNumber(indexPath.item+1)
        frameCollectionViewItem.itemIndex = indexPath.item
        frameCollectionViewItem.resetImage() // Remove current image
        
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
        deselectAll()
        
        for indexPath in indexPaths {
            guard let item = collectionView.item(at: indexPath) as? FrameCollectionViewItem else {continue}
            
            selectedRow = indexPath
            item.setHighlight(selected: true)
            
            break
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        selectedRow = nil
        deselectAll()
    }

    // MARK: Drag and drop
    private func collectionView(collectionView: NSCollectionView, canDragItemsAtIndexes indexes: NSIndexSet, withEvent event: NSEvent) -> Bool {
        return true
    }
    
    // Add the image from the cell to the drag'n'drop handler
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        guard let item = collectionView.item(at: indexPath) as? FrameCollectionViewItem,
              let imgView = item.imageView,
              let img = imgView.image else {
                return nil
        }
        
        return img
    }
    
    
    // When dragging starts?
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
        indexPathsOfItemsBeingDragged = indexPaths
    }
    
    // Dragging ends, reset drag variables
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
        indexPathsOfItemsBeingDragged = nil
    }
    
    // Is the drag allowed (And if so, what type of event is needed?)
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionViewDropOperation>) -> NSDragOperation {
        
        if proposedDropOperation.pointee == NSCollectionViewDropOperation.on {
            proposedDropOperation.pointee = NSCollectionViewDropOperation.before
        }
        
        if indexPathsOfItemsBeingDragged == nil {
            return NSDragOperation.copy
        } else {
            return NSDragOperation.move
        }
    }
    
    // On drag complete
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionViewDropOperation) -> Bool {
        // From outside (Finder, or whatever)
        if indexPathsOfItemsBeingDragged == nil {
            
            // Enumerate URLs, load images, and insert into currentImages
            var dropped:[NSImage] = []
            draggingInfo.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.concurrent, for: collectionView, classes: [NSURL.self], searchOptions: [NSPasteboardURLReadingFileURLsOnlyKey : NSNumber(value: true)]) { (draggingItem, idx, stop) in
                if let url = draggingItem.item as? URL,
                   let image = NSImage(contentsOf: url){
                    dropped.append(image)
                }
            }
            
            // One empty frame, remove this and insert new images
            if currentImages.count == 1 && currentImages[0] == nil {
                currentImages.removeAll()
                currentImages = dropped
            }
            else { // Append to frames already in view
                for n in 0 ..< dropped.count {
                    currentImages.insert(dropped[n], at: indexPath.item+n)
                }
            }
            
            // Reload
            imageCollectionView.reloadData()
            
            return true
        }
        
        // From inside the collectionview
        let indexPathOfFirstItemBeingDragged = indexPathsOfItemsBeingDragged.first!
        var toIndexPath: IndexPath
        if indexPathOfFirstItemBeingDragged.compare(indexPath) == .orderedAscending {
            toIndexPath = IndexPath(item: indexPath.item-1, section: indexPath.section)
        }
        else {
            toIndexPath = IndexPath(item: indexPath.item, section: indexPath.section)
        }
        
        // The index we're moving, the image, and the destination
        let dragItem = indexPathOfFirstItemBeingDragged.item
        let curImage = currentImages[dragItem]
        let newItem = toIndexPath.item
        currentImages.remove(at: dragItem)
        currentImages.insert(curImage, at: newItem)
        
        imageCollectionView.reloadData()
        imageCollectionView.deselectAll(nil)
        
        return true
    }
}
