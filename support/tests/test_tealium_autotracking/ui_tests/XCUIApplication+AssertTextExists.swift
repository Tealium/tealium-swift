//
//  XCUIApplication+AssertTextExists.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 28/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import XCTest


extension XCUIApplication {
    
    func assertStaticTextExists(text: String) {
        let predicate = NSPredicate(format: "value CONTAINS[c] %@ || label CONTAINS[c] %@", text, text) // don't know why value works for macOS and label for iOS and tvOS
        XCTAssertTrue(staticTexts
            .containing(predicate).firstMatch
            .waitForExistence(timeout: 5),
                      "Can not find \(text)")
    }
}
