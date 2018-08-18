//
//  DrawingOptionsHandler.swift
//  ImageFun
//
//  Created by Christian Lundtofte on 26/05/2017.
//  Copyright © 2017 Christian Lundtofte. All rights reserved.
//

import Foundation
import Cocoa

class DrawingOptionsHandler {
    static let colorChangedNotificationName = Notification.Name(rawValue: "ColorChangedOutside")
    static let backgroundColorChangedNotificationName = Notification.Name(rawValue: "BackgroundColorChanged")
    static let usedEyeDropperNotificationName = Notification.Name(rawValue: "UsedEyeDropper")
    
    static let shared = DrawingOptionsHandler()
    
    var drawingColorPtr : [Int] = NSColor.blue.getRGBAr()
    
    private var _drawingColor = NSColor.blue;
    var drawingColor : NSColor  {
        get {
            return _drawingColor
        }
        set {
            _drawingColor = newValue
            drawingColorPtr = _drawingColor.getRGBAr()
        }
    }
    var imageBackgroundColor:NSColor = NSColor.lightGray
    
    var isPickingColor = false
    
    var brushSize:Int = 1
}
