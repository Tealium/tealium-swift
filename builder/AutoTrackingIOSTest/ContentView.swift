// 
// ContentView.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import SwiftUI
import TealiumAutotracking

struct AutotrackingView: View {
    
    var body: some View {
        Text("Autotracked view")
            .autoTracking(viewSelf: self)
    }
}

struct ContentView: View {
    @State var count = 0
    @State var name: String = "RootView0"
    
    var body: some View {
        VStack {
            NavigationView {
                List {
                    NavigationLink("Launch ViewController", destination:
                        TealiumViewTrackable {
                            #if os(iOS) || os(tvOS)
                            ViewControllerWrapper()
                            #else
                            SomeView()
                            #endif
                        }
                    )
                    .autoTracked(name: $name)
                    .onDisappear {
                        self.count += 1
                        self.name = "RootView\(count)"
                    }
                    NavigationLink("Launch Second View", destination:
                        TealiumViewTrackable(constantName: "SecondView") {
                            SomeView()
                        }
                    )
                    NavigationLink("Launch Third View", destination:
                        AutotrackingView()
                    )
                    #if os(iOS) || os(tvOS)
                    NavigationLink("Launch Default UIViewController", destination:
                        BaseUIViewControllerWrapper()
                    )
                    #endif
                }
            }
        }
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
