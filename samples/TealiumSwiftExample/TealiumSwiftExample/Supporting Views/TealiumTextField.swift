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
    let onCommit: (() -> ())?
    
    public init(_ value: Binding<String>,
                secure: Bool = false,
                imageName: String? = nil,
                placeholder: String? = nil,
                onCommit: (() -> ())? = nil) {
        self._value = value
        self.isSecure = secure
        self.imageName = imageName
        self.placeholder = placeholder
        self.onCommit = onCommit
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
                if #available(iOS 15.0, *) {
                    TextField(placeholder ?? "", text: $value)
                        .foregroundColor(.tealBlue)
                        .accentColor(.tealBlue)
                        .onSubmit {
                            onCommit?()
                        }
                } else {
                    TextField(placeholder ?? "", text: $value, onCommit: {
                        onCommit?()
                    })
                        .foregroundColor(.tealBlue)
                        .accentColor(.tealBlue)
                }
            }
            if let onCommit = onCommit {
                Button {
                    onCommit()
                } label: {
                    Text("Apply")
                        .frame(width: 60, height: 50)
                        .background(Color.tealBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
          }
        .frame(width: 200.0)
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.tealBlue, lineWidth: 1))
    }
}
