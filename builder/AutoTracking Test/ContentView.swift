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
                List {
                    NavigationLink("Launch ViewController", destination:
                                    TealiumViewTrackable {
                                        #if os(iOS)
                                        ViewControllerWrapper()
                                        #else
                                        SomeView()
                                        #endif
                                    }
                    )
                    .autoTracked(name: $name)
                    .onDisappear {
                        self.count += 1
                        self.name = "Root View \(count)"
                    }
                    NavigationLink("Launch Second View", destination:
                                    TealiumViewTrackable(constantName: "Second View") {
                                        SomeView()
                                    }
                    )
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

struct SomeView: View {
    var body: some View {
        Group {
            Spacer()
            Text("Some Text")
            Spacer()
        }
    }
}
