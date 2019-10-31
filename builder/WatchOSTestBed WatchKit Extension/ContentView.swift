//
//  ContentView.swift
//  watchOSApp WatchKit Extension
//
//  Created by Craig Rouse on 15/10/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(content: {
                Text("Watch Demo App")
                Spacer()
                
                Button(action: {
                    print("Track View")
                    TealiumWatchHelper.shared.trackView(title: "Watch View", data: nil)
                },
                   label: {
                    Text("Track View")
                }).padding(.all)
                
                Button(action: {
                     print("Track Event")
                    TealiumWatchHelper.shared.track(title: "Watch Event", data: nil)
                },
                label: {
                     Text("Track Event")
                }).padding(.all)
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
