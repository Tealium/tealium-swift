//
//  TealiumTextField.swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.

import SwiftUI

public struct TealiumTextField: View {
    @Binding var value: String
    var isSecure: Bool
    var imageName: String?
    var placeholder: String?
    
    public init(_ value: Binding<String>,
        secure: Bool = false,
        imageName: String? = nil,
        placeholder: String? = nil) {
        self._value = value
        self.isSecure = secure
        self.imageName = imageName
        self.placeholder = placeholder
    }
    
    public var body: some View {
        HStack {
            if let imageName = imageName {
                Image(systemName: imageName)
                  .foregroundColor(.tealBlue)
            }
            if isSecure {
                SecureField(placeholder ?? "", text: $value)
            } else {
                TextField(placeholder ?? "", text: $value)
                  .foregroundColor(.tealBlue)
                  .accentColor(.tealBlue)
            }
          }
        .frame(width: 200.0)
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.tealBlue, lineWidth: 1))
    }
}
