//
//  ContentView.swift
//  TealiumSwiftExample
//
//  Created by Christina S on 11/8/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var traceId: String = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Button(action: {
                    TealiumHelper.trackView(title: "screen_view", data: nil)
                }) {
                    Text("Track View")
                }
                Button(action: {
                    TealiumHelper.trackView(title: "button_click",
                                            data: ["event_category": "example",
                                                   "event_action": "click",
                                                   "event_label": "Track Event"])
                }) {
                    Text("Track Event")
                }
                TextField("Trace ID", text: $traceId).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 150)
                Button(action: {
                    TealiumHelper.joinTrace(self.traceId)
                }) {
                    Text("Start Trace")
                }
                Button(action: {
                    TealiumHelper.leaveTrace()
                }) {
                    Text("Leave Trace")
                }
            Spacer()
                }.navigationBarTitle("TealiumSwiftExample", displayMode: .inline).padding(50)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
          ContentView().previewDevice(PreviewDevice(rawValue: "iPhone X"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 8"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        }
        
    }
}
