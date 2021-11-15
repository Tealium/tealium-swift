// The MIT License (MIT)
// Copyright (c) 2018 Read Evaluate Press, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import Foundation

/**
 A type-erased `Encodable` value.

 The `AnyEncodable` type forwards encoding responsibilities
 to an underlying value, hiding its specific underlying type.

 You can encode mixed-type values in dictionaries
 and other collections that require `Encodable` conformance
 by declaring their contained type to be `AnyEncodable`:

 let dictionary: [String: AnyEncodable] = [
 "boolean": true,
 "integer": 1,
 "double": 3.14159265358979323846,
 "string": "string",
 "array": [1, 2, 3],
 "nested": [
 "a": "alpha",
 "b": "bravo",
 "c": "charlie"
 ]
 ]

 let encoder = JSONEncoder()
 let json = try! encoder.encode(dictionary)
 */

extension Encodable {
  fileprivate func encode(to container: inout SingleValueEncodingContainer) throws {
    try container.encode(self)
  }
}

public struct AnyEncodable: Encodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

protocol _AnyEncodable {
    var value: Any { get }
    init<T>(_ value: T?)
}

extension AnyEncodable: _AnyEncodable {}

// MARK: - Encodable
// swiftlint:disable cyclomatic_complexity
extension _AnyEncodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let enc = value as? Encodable {
            try enc.encode(to: &container)
            return;
        }
        
        switch value {
        case let number as NSNumber:
            // We could also add Encodable protocol conformance to NSNumber and therefore enter in the previous if case
            // But it would be public and would interfere with any other third party implementation of that same protocol
            try encode(nsnumber: number, into: &container)
        case is NSNull, is Void:
            try container.encodeNil()
        case let subString as Substring:
            try String(subString).encode(to: &container)
        case let string as String: // Converts NSString which are not encodable
            try string.encode(to: &container)
        case let date as Date: // Converts NSDate which are not encodable
            try date.encode(to: &container)
        case let array as [Any?]:
            try container.encode(array.map {
                $0 as? AnyCodable ?? AnyCodable($0)
            })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues {
                $0 as? AnyCodable ?? AnyCodable($0)
            })
        default:
            try container.encodeNil()
            let codingPath = container.codingPath
            let debugFail = { // Need to call this in a block so LLDB doesn't crash trying to access the container and we lose the debuggable state.
                let message = "EncodingError: AnyCodable value \(type(of:value)) cannot be encoded, codingPath: \(codingPath). You can only add JSON encodable values to the data layer."
                assertionFailure(message)
                print(message + " Replacing value with null in this release build.")
            }
            debugFail()
        }
    }

    private func encode(nsnumber: NSNumber, into container: inout SingleValueEncodingContainer) throws {
        let encodable: Encodable
        switch CFNumberGetType(nsnumber) {
        case .charType:
            encodable = nsnumber.boolValue
        case .sInt8Type:
            encodable = nsnumber.int8Value
        case .sInt16Type:
            encodable = nsnumber.int16Value
        case .sInt32Type:
            encodable = nsnumber.int32Value
        case .sInt64Type:
            encodable = nsnumber.int64Value
        case .shortType:
            encodable = nsnumber.uint16Value
        case .longType:
            encodable = nsnumber.uint32Value
        case .longLongType:
            encodable = nsnumber.uint64Value
        case .intType, .nsIntegerType, .cfIndexType:
            encodable = nsnumber.intValue
        case .floatType, .float32Type:
            encodable = nsnumber.floatValue
        case .doubleType, .float64Type, .cgFloatType:
            let d = Double(truncating: nsnumber)
            /**
             * Double.greatestFiniteMagnitude when passed via NSNumber to decimalValue becomes nan. But actually is still a valid Double.
             * NSNumber(Double.greatestFiniteMagnitude).decimalValue -> NaN -> NOT Encodable
             *
             * Using Double conversion of truncating nsnumber (from which decimalValue is nan) still resolves in that valid Double
             * Double(truncating: NSNumber(Double.greatestFiniteMagnitude)) -> Double.greatestFiniteMagnitude -> Encodable
             *
             * We use then Double.nan, Double.infinity or, eventally Double.greatestFiniteMagnitude, by just using the Double(truncating: nsnumber)
             */
            if nsnumber == NSDecimalNumber.notANumber || nsnumber.decimalValue.isNaN || d == Double.infinity {
                encodable = d
            } else {
                encodable = nsnumber.decimalValue
            }
        #if swift(>=5.0)
        @unknown default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(nsnumber, context)
        #endif
        }
        try encodable.encode(to: &container)
    }
}

extension AnyEncodable: Equatable, EqualValues {
    public static func == (lhs: AnyEncodable, rhs: AnyEncodable) -> Bool {
        return areEquals(lhs: lhs.value, rhs: rhs.value)
    }
}
// swiftlint:enable cyclomatic_complexity
extension AnyEncodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension AnyEncodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyEncodable(\(value.debugDescription))"
        default:
            return "AnyEncodable(\(description))"
        }
    }
}

extension AnyEncodable: ExpressibleByNilLiteral {}
extension AnyEncodable: ExpressibleByBooleanLiteral {}
extension AnyEncodable: ExpressibleByIntegerLiteral {}
extension AnyEncodable: ExpressibleByFloatLiteral {}
extension AnyEncodable: ExpressibleByArrayLiteral {}
extension AnyEncodable: ExpressibleByDictionaryLiteral {}

extension _AnyEncodable {
    public init(nilLiteral _: ()) {
        self.init(nil as Any?)
    }

    public init(booleanLiteral value: Bool) {
        self.init(value)
    }

    public init(integerLiteral value: Int) {
        self.init(value)
    }

    public init(floatLiteral value: Double) {
        self.init(value)
    }

    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }

    public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        self.init([AnyHashable: Any](elements, uniquingKeysWith: { first, _ in first }))
    }
}
// swiftlint:enable cyclomatic_complexity
