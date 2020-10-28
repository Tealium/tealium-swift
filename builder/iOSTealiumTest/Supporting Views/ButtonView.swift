//
//  ButtonView.swift
//  iOSTealiumTest
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import SwiftUI

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
