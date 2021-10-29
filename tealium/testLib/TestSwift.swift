//
//  File.swift
//  
//
//  Created by Enrico Zannini on 29/10/21.
//

import Foundation


@objc public class TestSwift: NSObject {
    public private(set) var text = "Hello, World!"

    @objc public override init() {
        print(text)
        super.init()
    }
}
