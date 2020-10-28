//
//  ContentView.swift
//  TealiumSwiftExample
//
//  Copyright © 2019 Tealium. All rights reserved.
//
import SwiftUI

struct ContentView: View {
    @State private var traceId: String = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                ButtonView(title: "Track View") {
                    TealiumHelper.trackView(title: "screen_view", dataLayer: nil)
                }
                ButtonView(title: "Track Event") {
                    TealiumHelper.trackEvent(title: "button_tapped",
                                            dataLayer: ["event_category": "example",
                                                   "event_action": "tap",
                                                   "event_label": "Track Event"])
                }
                TraceIdTextField(traceId: $traceId)
                ButtonView(title: "Start Trace") {
                    TealiumHelper.joinTrace(self.traceId)
                }
                ButtonView(title: "Leave Trace") {
                    TealiumHelper.leaveTrace()
                }
            Spacer()
                }.navigationBarTitle("TealiumSwiftExample", displayMode: .inline).padding(50)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ButtonView: View {
    var title: String
    var action: () -> Void
    
    init(title: String, _ action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
                Text(title)
                   .frame(width: 200.0)
                   .padding()
                   .background(Color.gray)
                   .foregroundColor(.white)
                   .cornerRadius(10)
                   .shadow(radius: 8)
                   .overlay(
                       RoundedRectangle(cornerRadius: 10)
                           .stroke(Color.purple, lineWidth: 2)
                   )
        }
    }
}

struct TraceIdTextField: View {
    @Binding var traceId: String
    var body: some View {
        HStack {
              Image(systemName: "person").foregroundColor(.gray)
              TextField("Enter your Trace ID", text: $traceId)
          }
        .frame(width: 200.0)
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1))
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
