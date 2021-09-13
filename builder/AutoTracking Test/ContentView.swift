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
    @State var name: String = "Root View 0"
    
    var body: some View {
            VStack {
                NavigationView {
                    NavigationLink("Launch ViewController", destination:
                                    TealiumViewTrackable {
                                        ViewControllerWrapper()
                                    }
                                   )
                    .autoTracked(name: $name)
                    .onDisappear {
                        self.count += 1
                        self.name = "Root View \(count)"
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
