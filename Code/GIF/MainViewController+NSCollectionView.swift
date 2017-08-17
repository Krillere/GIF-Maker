//
//  MainViewController+NSCollectionView.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 25/06/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Foundation
import Cocoa


extension MainViewController: NSCollectionViewDelegate, NSCollectionViewDataSource {
    

    // MARK: NSCollectionView
    // Sets up the collection view variables (Could probably be done in IB), and allows drag'n'drop
    // https://www.raywenderlich.com/145978/nscollectionview-tutorial
    // https://www.raywenderlich.com/132268/advanced-collection-views-os-x-tutorial
    func configureCollectionView() {
        // Layout
        // MARK: Size of cells here!
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 200.0, height: 240.0)
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
        paths.forEach { (path) in
            if let item = imageCollectionView.item(at: path) as? FrameCollectionViewItem {
                item.setHighlight(selected: false)
            }
        }
        
        selectedRow = nil
    }
    
    // MARK: General delegate / datasource (num items and items themselves)
    
    // Creates item(frame) in collection view
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "FrameCollectionViewItem", for: indexPath)
        
        // Cast to FrameCollectionView, set index and reset image (To remove old index image)
        guard let frameCollectionViewItem = item as? FrameCollectionViewItem else { return item }
        
        frameCollectionViewItem.delegate = self
        frameCollectionViewItem.setFrameNumber(indexPath.item+1)
        frameCollectionViewItem.itemIndex = indexPath.item
        frameCollectionViewItem.resetImage() // Remove current image
        frameCollectionViewItem.setHighlight(selected: false)
        
        if selectedRow != nil && selectedRow!.item == indexPath.item {
            frameCollectionViewItem.setHighlight(selected: true)
        }
        
        let frame = currentFrames[indexPath.item]
        
        // Set GIFFrame
        if let imgView = frameCollectionViewItem.imageView as? DragNotificationImageView {
            imgView.gifFrame = frame
            frameCollectionViewItem.durationTextField.stringValue = String(format: "%.3lf", frame.duration)
        }
        
        // If we have an image, insert it here
        if let img = frame.image {
            frameCollectionViewItem.setImage(img)
        }
        
        return item
    }
    
    // Number of items in section (Number of frames)
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentFrames.count
    }
    
    
    // Selection of items
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
    
    
    // When dragging starts
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
    
    // On drag complete (Frames inserted or moved here)
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionViewDropOperation) -> Bool {
        // From outside (Finder, or whatever)
        if indexPathsOfItemsBeingDragged == nil {
            handleOutsideDrag(draggingInfo: draggingInfo, indexPath: indexPath)
        }
        else { // Moving frames inside the app
            handleInsideDrag(indexPath: indexPath)
        }
        
        imageCollectionView.reloadData()
        deselectAll()
        
        return true
    }
    
    
    // Inserts frames that were dragged from outside the app
    func handleOutsideDrag(draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
        
        // Enumerate URLs and load images
        var droppedImages:[NSImage] = []
        draggingInfo.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.concurrent,
                                            for: imageCollectionView,
                                            classes: [NSURL.self],
                                            searchOptions: [NSPasteboardURLReadingFileURLsOnlyKey : NSNumber(value: true)]) { (draggingItem, idx, stop) in
            if let url = draggingItem.item as? URL,
                let image = NSImage(contentsOf: url) {
                droppedImages.append(image)
            }
        }
        
        
        // Any gifs?
        let hasGifs = droppedImages.index { (img) -> Bool in
            return GIFHandler.isAnimatedGIF(img)
        }
        
        if let gifIndex = hasGifs { // A gif was dragged
            let alert = self.createAskImportAlert()
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (resp) in
                if resp == NSAlertFirstButtonReturn { // Replace all with gif
                    let gif = droppedImages[gifIndex]
                    self.loadAndSetGIF(image: gif)
                }
                else { // No clicked. Remove gif, and insert frames
                    droppedImages.remove(at: gifIndex)
                    self.insertImages(images: droppedImages, at: indexPath)
                }
            })
        }
        else {
            // Insert frames
            self.insertImages(images: droppedImages, at: indexPath)
        }
        
    }
    
    
    // MARK: Helpers
    // Inserts the given images
    func insertImages(images: [NSImage], at indexPath: IndexPath) {
        var frameAr:[GIFFrame] = []
        images.forEach { (image) in
            let frame = GIFFrame(image: image)
            frameAr.append(frame)
        }
        
        if images.count == 0 {
            return
        }
        
        // One empty frame, remove this and insert new images
        if currentFrames.count == 1 && currentFrames[0].image == nil {
            currentFrames.removeAll()
            currentFrames = frameAr
        }
        else { // Append to frames already in view
            for n in 0 ..< frameAr.count {
                currentFrames.insert(frameAr[n], at: indexPath.item+n)
            }
        }
        
        self.selectedRow = nil
        self.imageCollectionView.reloadData()
    }
    
    // Moves frames that were dragged inside the app
    func handleInsideDrag(indexPath: IndexPath) {
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
        let curFrame = currentFrames[dragItem]
        let newItem = toIndexPath.item
        currentFrames.remove(at: dragItem)
        currentFrames.insert(curFrame, at: newItem)
    }
}
