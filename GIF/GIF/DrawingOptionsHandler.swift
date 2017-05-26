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
    
    static let shared = DrawingOptionsHandler()
    
    var drawingColor:NSColor = NSColor.blue
    var imageBackgroundColor:NSColor = NSColor.lightGray
    
    var isPickingColor = false
}
