//
//  Document.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 28/06/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Cocoa

class Document: NSDocument {

    /*
    override var windowNibName: String? {
        // Override returning the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
        return "Document"
    }
    */

    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        
        
        // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        //throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        if let gif = NSImage(data: data) {
            let frames = GIFHandler.loadGIF(with: gif)
            let userInfo = ["info":frames]
            NotificationCenter.default.post(name: ViewController.loadedDocumentFramesNotificationName, object: self, userInfo: userInfo)
        }
    }

    override class func autosavesInPlace() -> Bool {
        return false
    }

}
