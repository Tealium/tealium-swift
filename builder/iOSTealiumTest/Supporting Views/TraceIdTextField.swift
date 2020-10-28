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
                .foregroundColor(.gray)
              TextField("Enter your Trace ID", text: $traceId)
                .foregroundColor(.blue)
                .accentColor(.blue)
          }
        .frame(width: 200.0)
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1))
    }
}
