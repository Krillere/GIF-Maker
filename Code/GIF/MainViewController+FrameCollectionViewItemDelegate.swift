//
//  MainViewController+FrameCollectionViewItemDelegate.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 17/08/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Foundation
import Cocoa

extension MainViewController: FrameCollectionViewItemDelegate {
    
    // MARK: FrameCollectionViewItemDelegate
    func removeFrame(item: FrameCollectionViewItem) {
        
        // If there's one frame, reset it
        if currentFrames.count == 1 {
            currentFrames[0] = GIFFrame.emptyFrame
            
        }
        else {
            // Remove the index and reload everything
            let index = item.itemIndex
            currentFrames.remove(at: index)
        }
        
        deselectAll()
        imageCollectionView.reloadData()
    }
    
    func editFrame(item: FrameCollectionViewItem) {
        let index = item.itemIndex
        showEditing(withIndex: index)
    }
    
    // An image was dragged onto the DragNotificationImageView
    func frameImageChanged(item: FrameCollectionViewItem) {
        guard let imgView = item.imageView as? DragNotificationImageView else { return }
        guard let img = imgView.image else { return }
        
        if GIFHandler.isAnimatedGIF(img) { // Dragged GIF
            // Import?
            let alert = self.createAskImportAlert()
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (resp) in
                if resp == NSAlertFirstButtonReturn { // Replace
                    self.loadAndSetGIF(image: img)
                }
                else { // TODO: Load first image, I guess
                }
            })
        }
        else { // Dragged regular image
            let newFrame = GIFFrame(image: img)
            if let frame = imgView.gifFrame {
                newFrame.duration = frame.duration
            }
            
            currentFrames[item.itemIndex] = newFrame
        }
        
        self.selectedRow = nil
        self.imageCollectionView.reloadData()
    }
    
    // User clicked DragNotificationImageView
    func frameImageClicked(item: FrameCollectionViewItem) {
        guard let imgView = item.imageView as? DragNotificationImageView else { return }
        
        // Show panel
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "gif", "tiff", "bmp"]
        panel.beginSheetModal(for: self.view.window!) { (response) -> Void in
            
            imgView.resignFirstResponder()
            self.addFrameButton.becomeFirstResponder()
            
            if response != NSFileHandlingPanelOKButton {
                return
            }
            
            // Insert image into imageview and 'currentImages' and reload
            guard let URL = panel.url else { return }
            guard let image = NSImage(contentsOf: URL) else { self.showError("Could not load image."); return }
            
            if GIFHandler.isAnimatedGIF(image) { // Gif
                // Import?
                let alert = self.createAskImportAlert()
                
                alert.beginSheetModal(for: self.view.window!, completionHandler: { (resp) in
                    if resp == NSAlertFirstButtonReturn { // Replace
                        self.importGIF(from: URL)
                    }
                    else { // TODO: Load first image, I guess
                    }
                })
                
            }
            else { // Single image
                let newFrame = GIFFrame(image: image)
                if let frame = imgView.gifFrame {
                    newFrame.duration = frame.duration
                }
                
                self.currentFrames[item.itemIndex] = newFrame
            }
            
            self.imageCollectionView.reloadData()
        }
    }
    
    // Frame duration changed
    func frameDurationChanged(item: FrameCollectionViewItem) {
        guard let imgView = item.imageView as? DragNotificationImageView,
            let frame = imgView.gifFrame,
            let newDuration = Double(item.durationTextField.stringValue) else { return }
        frame.duration = newDuration
    }

    
    // MARK: Helpers
    func createAskImportAlert() -> FancyAlert {
        let alert = FancyAlert()
        alert.messageText = "GIF Found"
        alert.informativeText = "Do you want to import it and replace all frames with the contents of this GIF?"
        
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        return alert
    }
}
