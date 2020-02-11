//
//  ContentView.swift
//  TealiumSwiftMacOSExample
//
//  Created by Christina S on 2/7/20.
//  Copyright © 2020 Tealium. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var traceId: String = ""
    var body: some View {
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
                TextField("Trace ID", text: $traceId).frame(width: 250)
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
