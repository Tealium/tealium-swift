//
//  ContentView.swift
//  iOSTealiumTest
//
//  Copyright © 2020 Tealium. All rights reserved.
//
import SwiftUI

struct ContentView: View {
    @State private var traceId: String = ""
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TraceIdTextField(traceId: $traceId)
                        .padding(.bottom, 20)
                    ButtonView(title: "Start Trace") {
                        TealiumHelper.shared.joinTrace(self.traceId)
                    }
                    ButtonView(title: "Leave Trace") {
                        TealiumHelper.shared.leaveTrace()
                    }
                    ButtonView(title: "Track View") {
                        TealiumHelper.shared.trackView(title: "screen_view", data: nil)
                    }
                    ButtonView(title: "Track Event") {
                        TealiumHelper.shared.track(title: "button_tapped",
                                                data: ["event_category": "example",
                                                       "event_action": "tap",
                                                       "event_label": "Track Event"])
                    }
                    ButtonView(title: "Hosted Data Layer") {
                        TealiumHelper.shared.track(title: "hdl-test",
                                                   data: ["product_id": "abc123"])
                    }
                    ButtonView(title: "SKAdNetwork Conversion") {
                        TealiumHelper.shared.track(title: "conversion_event",
                                                   data: ["conversion_value": 10])
                    }
                    ButtonView(title: "Toggle Consent Status") {
                        TealiumHelper.shared.resetConsentPreferences()
                    }
                    ButtonView(title: "Reset Consent") {
                        TealiumHelper.shared.toggleConsentStatus()
                    }
                    Spacer()
                }
                .navigationTitle("iOSTealiumTest")
                .navigationBarTitleDisplayMode(.inline)
                .padding(50)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
          ContentView().previewDevice(PreviewDevice(rawValue: "iPhone X"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 8"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 11 SE (1st generation)"))
        }
        
    }
}
