//
//  UIColor+Hex.swift
//
//  Created by Christina Schell on 4/4/21.
//

#if os(iOS)
import UIKit

public extension UIColor {
    public convenience init(hex: String, alpha: CGFloat = 1) {
        let chars = Array(hex.dropFirst())
        self.init(red:   .init(strtoul(String(chars[0...1]),nil,16))/255,
                  green: .init(strtoul(String(chars[2...3]),nil,16))/255,
                  blue:  .init(strtoul(String(chars[4...5]),nil,16))/255,
                  alpha: alpha)}
}
#endif
