//
//  TraceIdTextField.swift
//  iOSTealiumTest
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import SwiftUI

struct TraceIdTextField: View {
    @Binding var traceId: String
    var body: some View {
        HStack {
              Image(systemName: "person")
                .foregroundColor(.tealBlue)
              TextField("Enter your Trace ID", text: $traceId)
                .foregroundColor(.tealBlue)
                .accentColor(.tealBlue)
          }
        .frame(width: 200.0)
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.tealBlue, lineWidth: 1))
    }
}
