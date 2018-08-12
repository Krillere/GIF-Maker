//
//  NSColorExtension.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 12/08/2018.
//  Copyright © 2018 Christian Lundtofte. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor {
    func getRGBAr() -> [Int] {
        return [Int(self.redComponent * 255.99999), Int(self.greenComponent * 255.99999), Int(self.blueComponent * 255.99999), Int(self.alphaComponent * 255.99999)]
    }
}
