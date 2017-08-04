/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A simple struct representing an item that can be searched for.
*/

import CoreLocation

struct SearchableItem: Equatable {
    
    // MARK: Properties
    
    let identifier: String
    
    let title: String
    
    let location: CLLocationCoordinate2D
}

// MARK: Equatable

func ==(lhs: SearchableItem, rhs: SearchableItem)-> Bool {
    // Two `SearchableItem`s are considered equal if their identifiers.
    return lhs.identifier == rhs.identifier
}