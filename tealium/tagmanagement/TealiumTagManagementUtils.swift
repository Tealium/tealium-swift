//
//  TealiumTagManagementUtils.swift
//  tealium-swift
//
//  Created by Craig Rouse on 12/8/2018
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if tagmanagement
import TealiumCore
#endif

public extension Dictionary where Key == String, Value == Any {

    /// Generates a formatted utag.track call for the Tealium iQ webview
    /// - Returns: A String representing a utag.track call to be sent to the Tealium iQ webview
    var tealiumJavaScriptTrackCall: String? {
        guard let encodedPayload = jsonStringWithDictionary(self) else {
                        return nil
        }
        let trackType = self.legacyType
        return "utag.track(\'\(trackType)\',\(encodedPayload))"
    }

    /// Gets the call type from the track call. Defaults to "link" unless callType is specified
    /// - Returns: The type of event based on the "call_type" variable in the dictionary.
    var legacyType: String {
        return self[TealiumKey.callType] as? String ?? "link"
    }
}
