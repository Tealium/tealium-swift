// 
// ContentView.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import SwiftUI
import TealiumAutotracking


struct ContentView: View {
    @AutoTracked var name = ((name: "hello", track: false))
    var body: some View {
        VStack {
            NavigationView {
                NavigationLink("Launch ViewController", destination: ViewControllerWrapper())
            }
        }.onAppear {
            _ = name
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
