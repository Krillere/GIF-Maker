//
//  ViewController+NSCollectionView.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 25/06/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Foundation
import Cocoa


extension ViewController: NSCollectionViewDelegate, NSCollectionViewDataSource, FrameCollectionViewItemDelegate {
    
    // MARK: FrameCollectionViewitemDelegate
    func removeFrame(item: FrameCollectionViewItem) {
        // Can we remove this?
        if currentFrames.count == 1 {
            return // Nope.
        }
        
        // Remove the index and reload everything
        let index = item.itemIndex
        currentFrames.remove(at: index)
        
        deselectAll()
        imageCollectionView.reloadData()
    }
    
    func editFrame(item: FrameCollectionViewItem) {
        let index = item.itemIndex
        showEditing(withIndex: index)
    }
    
    // MARK: NSCollectionView
    // Sets up the collection view variables (Could probably be done in IB), and allows drag'n'drop
    // https://www.raywenderlich.com/145978/nscollectionview-tutorial
    // https://www.raywenderlich.com/132268/advanced-collection-views-os-x-tutorial
    func configureCollectionView() {
        // Layout
        // MARK: Size of cells here!
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 200.0, height: 222.0)
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
        
        
        
        // If we have an image, insert it here
        if let img = currentFrames[indexPath.item].image {
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
        
        // Enumerate URLs, load images, and insert into currentImages
        var dropped:[GIFFrame] = []
        draggingInfo.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.concurrent, for: imageCollectionView, classes: [NSURL.self], searchOptions: [NSPasteboardURLReadingFileURLsOnlyKey : NSNumber(value: true)]) { (draggingItem, idx, stop) in
            if let url = draggingItem.item as? URL,
                let image = NSImage(contentsOf: url){
                let frame = GIFFrame(image: image)
                dropped.append(frame)
            }
        }
        
        // One empty frame, remove this and insert new images
        if currentFrames.count == 1 && currentFrames[0].image == nil {
            currentFrames.removeAll()
            currentFrames = dropped
        }
        else { // Append to frames already in view
            for n in 0 ..< dropped.count {
                currentFrames.insert(dropped[n], at: indexPath.item+n)
            }
        }
        
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
