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
    
    // Constants
    static let RemoveFrameNotificationName = NSNotification.Name(rawValue: "RemoveFrame")
    static let ImageClickedNotificationName = NSNotification.Name(rawValue: "ImageClicked")
    static let ImageChangedNotificationName = NSNotification.Name(rawValue: "ImageChanged")
    
    // UI elements
    @IBOutlet var imageCollectionView:NSCollectionView!
    @IBOutlet var secondsPerFrameTextField:NSTextField!
    @IBOutlet var addFrameButton:NSButton!
    @IBOutlet var loopsTextField:NSTextField!
    
    // Fields used in UI handling
    var currentImages:[NSImage?] = [nil] // Allows null as they are shown as empty frames. Default is 1 empty image, to show something in UI
    var selectedRow:IndexPath? = nil // Needed for inserting and removing item
    var indexPathsOfItemsBeingDragged: Set<IndexPath>! // Paths of items being dragged (If dragging inside the app)
    
    
    // MARK: View setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        
        // Listeners for events regarding frames and images
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.removeFrameCalled(sender:)),
                                               name: ViewController.RemoveFrameNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.clickedImageView(sender:)),
                                               name: ViewController.ImageClickedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.imageDraggedToImageView(sender:)),
                                               name: ViewController.ImageChangedNotificationName, object: nil)
        
        // GIFHandler events
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.gifError(sender:)),
                                               name: GIFHandler.ErrorNotificationName, object: nil)
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
    
    // View changing
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPreview" {
            if let viewController = segue.destinationController as? PreviewViewController {
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
                
                let previewImg = GIFHandler.createGIF(with: tmpImages, loops: loops, secondsPrFrame: spf)
                viewController.previewImage = previewImg
            }
        }
    }

    
    // MARK: Buttons
    // Adds a new frame
    @IBAction func addFrameButtonClicked(sender: AnyObject?) {
        if let indexPath = selectedRow { // Add after selectedRow
            currentImages.insert(nil, at: indexPath.item+1)
            selectedRow = IndexPath(item: indexPath.item+1, section: 0)
        }
        else { // Add empty frame
            currentImages.append(nil)
        }

        self.imageCollectionView.reloadData()
    }
    
    // Export a gif
    @IBAction func exportGIFButtonClicked(sender: AnyObject?) {
        guard let loops = Int(loopsTextField.stringValue) else {
            showError("Invalid value for loop count.")
            return
        }
        guard let spf = Float(secondsPerFrameTextField.stringValue) else {
            showError("Invalid value for frame duration.")
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
                if let url = panel.url {
                    self.importGIF(from: url)
                }
            }
        }
    }
    
    // Reset everything
    @IBAction func resetButtonClicked(sender: AnyObject?) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.informativeText = "This will remove everything, are you sure?"
        alert.messageText = "Are you sure?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        alert.beginSheetModal(for: self.view.window!) { (resp) in
            if resp == NSAlertFirstButtonReturn { // Yes clicked, reset
                self.currentImages = [nil]
                self.secondsPerFrameTextField.stringValue = String(GIFHandler.DefaultFrameDuration)
                self.loopsTextField.stringValue = String(GIFHandler.DefaultLoops)
                self.imageCollectionView.reloadData()
                self.deselectAll()
            }
        }
    }
    
    // Preview
    @IBAction func previewButtonClicked(sender: AnyObject?) {
        self.performSegue(withIdentifier: "ShowPreview", sender: self)
    }
    
    
    // MARK: Helpers
    // Imports a gif from a given location
    func importGIF(from: URL) {
        if let image = NSImage(contentsOf: from) {
            // Set values from the .GIF
            let newValues = GIFHandler.loadGIF(with: image)
            
            self.currentImages = newValues.images
            self.secondsPerFrameTextField.stringValue = String(newValues.secondsPrFrame)
            self.loopsTextField.stringValue = String(newValues.loops)
            
            self.selectedRow = nil
            self.imageCollectionView.reloadData()
        }
    }
    
    // MARK: NotificationCenter calls (Mainly by UI components)
    // A frame wants to be removed (Get index of sender, and remove from 'currentImages')
    func removeFrameCalled(sender: NSNotification) {
        guard let object = sender.object as? FrameCollectionViewItem else { return }
        
        // Remove the index and reload everything
        let index = object.itemIndex
        currentImages.remove(at: index)
        
        deselectAll()
        imageCollectionView.reloadData()
    }

    // An image was dragged to an imageView
    // Replace the image at the views location to the new one
    func imageDraggedToImageView(sender: NSNotification) {
        guard let imgView = sender.object as? DragNotificationImageView,
              let owner = imgView.ownerCollectionViewItem,
              let img = imgView.image else { return }
        
        currentImages[owner.itemIndex] = img
        self.selectedRow = nil
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
    
    // Notification when an error occurs in GIFHandler
    func gifError(sender: NSNotification) {
        guard let userInfo = sender.userInfo,
              let error = userInfo["Error"] as? String else {
            return
        }
        
        showError(error)
    }
    
    // Shows an error
    func showError(_ error: String) {
        let alert = NSAlert()
        alert.messageText = "An error occurred"
        alert.informativeText = error
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
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
        
        selectedRow = nil
    }
    
    // MARK: General delegate / datasource (num items and items themselves)
    
    // Creates item(frame) in collection view
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "FrameCollectionViewItem", for: indexPath)
        
        // Cast to FrameCollectionView, set index and reset image (To remove old index image)
        guard let frameCollectionViewItem = item as? FrameCollectionViewItem else { print("NO"); return item}
        frameCollectionViewItem.setFrameNumber(indexPath.item+1)
        frameCollectionViewItem.itemIndex = indexPath.item
        frameCollectionViewItem.resetImage() // Remove current image
        frameCollectionViewItem.setHighlight(selected: false)
        
        if selectedRow != nil && selectedRow!.item == indexPath.item {
            frameCollectionViewItem.setHighlight(selected: true)
        }
        
        
        
        // If we have an image, insert it here
        if let img = currentImages[indexPath.item] {
            frameCollectionViewItem.setImage(img)
        }
        
        return item
    }

    // Number of items in section (Number of frames)
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentImages.count
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
        var dropped:[NSImage] = []
        draggingInfo.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.concurrent, for: imageCollectionView, classes: [NSURL.self], searchOptions: [NSPasteboardURLReadingFileURLsOnlyKey : NSNumber(value: true)]) { (draggingItem, idx, stop) in
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
        let curImage = currentImages[dragItem]
        let newItem = toIndexPath.item
        currentImages.remove(at: dragItem)
        currentImages.insert(curImage, at: newItem)
    }
}
