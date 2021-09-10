// 
// ContentView.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import SwiftUI
import TealiumAutotracking

struct ContentView: View {
    @State var count = 0
    var name: String {
        "Root View \(count)"
    }
    var body: some View {
            VStack {
                NavigationView {
                        NavigationLink("Launch ViewController", destination:
                                        TealiumViewTrackable {
                                            ViewControllerWrapper()
                                        }
                                       )
                            .autoTracked(name: name)
                            .onDisappear {
                                count += 1
                            }
                }
            }
            .autoTracking(viewSelf: self)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


// reflect to container of the view

// maybe we could provide a container for all the app, and then apply autoTracking to the content once it changes

// Try to add autotracked on NavigationView children
// We could provide a Custom NavigationView
// Custom TabView and stuff like this
