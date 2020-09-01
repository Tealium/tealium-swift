//
//  Tealium.jsonEncoderDecoder.swift
//  TealiumCore
//
//  Created by Craig Rouse on 13/05/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Tealium {
    static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "Infinity", nan: "NaN")
        return encoder
    }

    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "Infinity", nan: "NaN")
        return decoder
    }
}
