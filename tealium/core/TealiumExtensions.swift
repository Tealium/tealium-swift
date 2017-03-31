//
//  TealiumExtensions.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

/**
     General Extensions that may be used by multiple objects.
*/
import Foundation

/**
 Extend boolvalue NSString function to Swift strings.
 */
extension String {
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }
}

extension URL {

    public var queryItems: [String: Any] {
        var params = [String: Any]()
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce([:], { (_, item) -> [String: Any] in
                params[item.name] = item.value
                return params
            }) ?? [:]
    }
    
    //    var queryItems: [String: Any]? {
//        
//        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
//            return nil
//        }
//        return components.queryItems
//        
////        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
////            .queryItems?
////            .flatMap { $0.dictionaryRepresentation }
////            .reduce([:], +)
//    }

}

/**
 Allows use of plus operator for array reduction calls.
 */
fileprivate func +<Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
    var result = lhs
    rhs.forEach{ result[$0] = $1 }
    return result
}

extension URLRequest {
    
    func asDictionary() -> [String : Any] {
        
        var result = [String:Any]()
        
        result["allowsCellularAccess"] = self.allowsCellularAccess ? "true" : "false"
        result["allHTTPHeaderFields"] = self.allHTTPHeaderFields
        result["cachePolicy"] = self.cachePolicy
        result["url"] = self.url?.absoluteString
        result["timeoutInterval"] = self.timeoutInterval
        result["httpMethod"] = self.httpMethod
        result["httpShouldHandleCookies"] = self.httpShouldHandleCookies
        result["httpShouldUsePipelining"] = self.httpShouldUsePipelining
        
        return result
    }
    
    mutating func assignHeadersFrom(dictionary: [String:Any]) {
        let sortedKeys = Array(dictionary.keys).sorted(by: <)
        for key in sortedKeys {
            guard let value = dictionary[key] as? String else {
                continue
            }
            self.addValue(value, forHTTPHeaderField: key)
        }
    }
}

extension URLQueryItem {
    var dictionaryRepresentation: [String: Any]? {
        if let value = value {
            return [name: value]
        }
        return nil
    }
    
}
