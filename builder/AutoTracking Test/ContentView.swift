// 
// ContentView.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import SwiftUI
import TealiumAutotracking

struct ContentView: View {
    var body: some View {
        VStack {
            NavigationView {
                NavigationLink("Launch ViewController", destination: ViewControllerWrapper())
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
