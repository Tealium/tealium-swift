//
//  XCTestCaseUtilities.swift
//  tealium-swift
//
//  Created by Christina Sund on 6/27/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import XCTest
import Foundation

extension XCTestCase {

    func loadStub(from file: String, with extension: String) -> Data {
        let bundle = Bundle(for: classForCoder)
        let url = bundle.url(forResource: file, withExtension: `extension`)
        return try! Data(contentsOf: url!)
    }

}

func loadStub(from file: String,
              with extension: String,
              for cls: AnyClass) -> Data {
    let bundle = Bundle(for: cls)
    let url = bundle.url(forResource: file, withExtension: `extension`)
    return try! Data(contentsOf: url!)
}
