//
//  XCTestCaseUtilities.swift
//  tealium-swift
//
//  Created by Christina S on 6/27/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
import XCTest

func loadStub(from file: String,
              _ cls: AnyClass) -> Data {
    let bundle = Bundle(for: cls)
    let url = bundle.url(forResource: file, withExtension: "json")
    return try! Data(contentsOf: url!)
}
