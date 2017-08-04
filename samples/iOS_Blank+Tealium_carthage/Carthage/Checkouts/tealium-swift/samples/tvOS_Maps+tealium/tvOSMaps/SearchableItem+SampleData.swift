/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Adds a set of sample data to `SearchableItem`.
*/

import CoreLocation

extension SearchableItem {
    
    /// A static sample set of `SearchableItem`s.
    static var sampleItems: [SearchableItem] = {
        return [
            SearchableItem(identifier: "id3", title: "Alcatraz Island", location: CLLocationCoordinate2DMake(37.82667, -122.423333)),
            SearchableItem(identifier: "id5", title: "Chinatown", location: CLLocationCoordinate2DMake(37.794722, -122.407222)),
            SearchableItem(identifier: "id8", title: "Coit Tower", location: CLLocationCoordinate2DMake(37.8025, -122.405833)),
            SearchableItem(identifier: "id7", title: "Ferry Building", location: CLLocationCoordinate2DMake(37.7955, -122.3937)),
            SearchableItem(identifier: "id2", title: "Fisherman's Wharf", location: CLLocationCoordinate2DMake(37.808333, -122.415556)),
            SearchableItem(identifier: "id1", title: "Golden Gate Bridge", location: CLLocationCoordinate2DMake(37.819722, -122.478611)),
            SearchableItem(identifier: "id4", title: "Golden Gate Park", location: CLLocationCoordinate2DMake(37.769722, -122.476944)),
            SearchableItem(identifier: "id9", title: "Lombard Street", location: CLLocationCoordinate2DMake(37.801944, -122.418889)),
            SearchableItem(identifier: "id6", title: "Union Square", location: CLLocationCoordinate2DMake(37.788056, -122.4075)),
        ]
    }()
    
    static var samplePopularItems: [SearchableItem] = {
        return [
            SearchableItem(identifier: "id3", title: "Alcatraz Island", location: CLLocationCoordinate2DMake(37.82667, -122.423333)),
            SearchableItem(identifier: "id2", title: "Fisherman's Wharf", location: CLLocationCoordinate2DMake(37.808333, -122.415556)),
            SearchableItem(identifier: "id6", title: "Union Square", location: CLLocationCoordinate2DMake(37.788056, -122.4075)),
        ]
    }()
}
