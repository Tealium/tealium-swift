//
//  String+Tealium.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

/// Extend `boolValue` NSString function to Swift strings.
extension String {
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }
}

public extension String {
    /// URL initializer does not actually validate web addresses successfully (it's too permissive), so this additional check is required￼.
    ///
    /// - Returns: `Bool` `true` if URL is a valid web address
    var isValidUrl: Bool {
        let urlRegexPattern = "^(https?://)?((www\\.)?([-a-zA-Z0-9]{1,63}\\.)*?[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]\\.[a-z]{2,6}|(([0-9]{1,3}\\.){3}[0-9]{1,3}))(:[0-9]{1,5})?(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
        guard let validURLRegex = try? NSRegularExpression(pattern: urlRegexPattern, options: []) else {
            return false
        }
        return validURLRegex.rangeOfFirstMatch(in: self, options: [], range: NSRange(self.startIndex..., in: self)).location != NSNotFound
    }
}

