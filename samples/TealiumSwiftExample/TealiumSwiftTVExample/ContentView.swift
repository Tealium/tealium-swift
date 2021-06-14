//
//  ContentView.swift
//  TealiumSwiftTVExample
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var traceId: String = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Button(action: {
                    TealiumHelper.shared.trackView(title: "screen_view", data: nil)
                }) {
                    Text("Track View")
                }
                Button(action: {
                    TealiumHelper.shared.trackView(title: "button_click",
                                            data: ["event_category": "example",
                                                        "event_action": "click",
                                                        "event_label": "Track Event"])
                }) {
                    Text("Track Event")
                }
                TextField("Trace ID", text: $traceId).frame(width: 250)
                Button(action: {
                    TealiumHelper.shared.joinTrace(self.traceId)
                }) {
                    Text("Start Trace")
                }
                Button(action: {
                    TealiumHelper.shared.leaveTrace()
                }) {
                    Text("Leave Trace")
                }
                Spacer()
            }.navigationBarTitle("TealiumSwiftExample").padding(50)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
