//
//  NSBezierPathExtension.swift
//  Smart GIF Maker
//
//  Created by Christian Lundtofte on 18/08/2018.
//  Copyright © 2018 Christian Lundtofte. All rights reserved.
//

import Foundation
import AppKit

extension NSBezierPath
{
    
//    func scaleAroundCenter(factor: CGFloat) {
//        let beforeCenter = CGPoint(x: NSMidX(self.bounds), y: NSMidY(self.bounds))
//
//        // SCALE path by factor
//        let scaleTransform = AffineTransform(scaleByX: factor, byY: factor)
//        self.transform(using: scaleTransform)
//
//        let afterCenter = CGPoint(x: NSMidX(self.bounds), y: NSMidY(self.bounds))
//        let diff = CGPoint(
//            x: beforeCenter.x - afterCenter.x,
//            y: beforeCenter.y - afterCenter.y)
//
//        let translateTransform = AffineTransform(scaleByX: diff.x, byY: diff.y)
//        self.transform(using: translateTransform)
//    }
//
//    func scale(fromSize: NSSize, toSize: NSSize) {
//        if fromSize.width == 0 || fromSize.height == 0 {
//            Swift.print("Should not happen")
//            return
//        }
//
//        let scaledWidth = toSize.width / fromSize.width
//        let scaledHeight = toSize.height / fromSize.height
//        print("Scale: \(scaledWidth), \(scaledHeight)")
//    }
//
    func scaleBy(_ mag: CGFloat) {
        // Scale
        let trans2 = AffineTransform(scaleByX: mag, byY: mag)
        self.transform(using: trans2)
        
        // Move
        let frame = self.bounds
        let curPos = frame.origin //CGPoint(x: NSMidX(frame), y: NSMidY(frame))
        let newPos = CGPoint(x: curPos.x * mag, y: curPos.y * mag)
        let xMove = newPos.x - curPos.x
        let yMove = newPos.y - curPos.y
        
        let trans = AffineTransform(translationByX: xMove, byY: yMove)
        self.transform(using: trans)
    }
}
