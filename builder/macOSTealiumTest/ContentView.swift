//
//  ContentView.swift
//  macOSTealiumTest
//
//  Copyright © 2020 Tealium. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var traceId: String = ""
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 20) {
                Text("macOSTealiumTest")
                    .font(.title)
                TextField("Enter Your Trace ID", text: $traceId)
                    .padding(.bottom, 20)
                Button("Start Trace") {
                    TealiumHelper.shared.joinTrace(self.traceId)
                }.padding()
                Button("Leave Trace") {
                    TealiumHelper.shared.leaveTrace()
                }.padding()
                Button("Track View") {
                    TealiumHelper.shared.trackView(title: "screen_view", data: nil)
                }.padding()
                Button("Track Event") {
                    TealiumHelper.shared.track(title: "button_tapped",
                                            data: ["event_category": "example",
                                                   "event_action": "tap",
                                                   "event_label": "Track Event"])
                }.padding()
                Spacer()
            }
            .padding(50)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

