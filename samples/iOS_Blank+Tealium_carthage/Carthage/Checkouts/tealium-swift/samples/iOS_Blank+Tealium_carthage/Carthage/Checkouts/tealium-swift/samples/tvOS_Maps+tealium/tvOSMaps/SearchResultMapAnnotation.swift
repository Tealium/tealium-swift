/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An `NSObject` subclass that implements the `MKAnnotation` protocol to allow `SearchableItem`s to be displayed on an `MKMapView`.
*/

import MapKit

class SearchResultMapAnnotation: NSObject, MKAnnotation {
    
    let item: SearchableItem
    
    var coordinate: CLLocationCoordinate2D {
        return item.location
    }
    
    var title: String? {
        return item.title
    }
    
    init(item: SearchableItem) {
        self.item = item
    }
}
