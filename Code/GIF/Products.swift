//
//  IAPStuff.swift
//  LiveMap
//
//  Created by Christian Lundtofte on 09/08/2016.
//  Copyright © 2016 Christian Lundtofte. All rights reserved.
//

import Foundation

public struct Products {
    
    fileprivate static let Prefix = "com.imakezappz.GIF."
    
    public static let Pro = Prefix + "pro"
    
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [Products.Pro]

    public static let store = IAPHelper(productIds: Products.productIdentifiers)
}
