//
//  Extensions.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 11/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
import JavaScriptCore

// swiftlint:disable all

let testCount = 10000
let queue = TealiumQueues.backgroundSerialQueue

public class JSExtension: DispatchValidator {
    public var id: String = "Extensions"
    var timings = [Int64]()
    public init() {
//        return;
        queue.asyncAfter(deadline: .now() + 15) {
            let time = self.timings
            var total: Int64 = 0
            for ms in time {
                total += ms
            }
            let result = total/Int64(time.count)
            print("EXTENSIONS JS average \(result) out of \(time.count) tests")
        }
    }
    public func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
//        return (true, nil)
        if let req = request as? TealiumTrackRequest {
            queue.async {
                self.runExtensions(data: req.trackDictionary)
            }
        }
        return (true, nil)
    }
    
    public func shouldDrop(request: TealiumRequest) -> Bool {
        true
    }
    
    public func shouldPurge(request: TealiumRequest) -> Bool {
        true
    }
    
    func runExtensions(data: [String: Any]) {
        let start = Date()
        NSLog("EXTENSIONS JS START")
        let context = JSContext()!
        setDataLayer(context: context, data: data + ["someKey": [true, true, false]])
        context.exceptionHandler = { context, error in
            NSLog("EXTENSIONS JS Exception \(error)")
        }
        
        addMethodWithCallback(context) { value in
            print(value)
        }
        for i in 1..<testCount {
            addKeyToContext(context, key: "\(i)")
        }
        let data = getDataLayer(context: context)
        let end = Date().millisecondsFrom(earlierDate: start)
        timings.append(end)
        NSLog("EXTENSIONS JS Final data: \(data)")
        NSLog("EXTENSIONS JS END \(end)")
        context.setObject(JSValue(undefinedIn: context), forKeyedSubscript: "datalayer" as NSString)
        
    }
    
    func addKeyToContext(_ context: JSContext, key: String) {
        context.evaluateScript("""
            datalayer["\(key)"] = \(key)
""")
    }
    
    func addMethodWithCallback(_ context: JSContext, completion: @escaping @convention(block) (JSValue?) -> Void) {
        let callback = JSValue(object: completion, in: context)!
        
        context.evaluateScript("""
            async function someAsync() {

            }
            function some(completion) {
                someAsync()
                    .then( () => {
                    completion("ciao")
                })
            }
""")
        let function = context.objectForKeyedSubscript("some" as NSString)
        function?.call(withArguments: [callback])
    }
    
    func setDataLayer(context: JSContext, data: [String: Any]) {
//        let jsvalue = JSValue(newObjectIn: context)
//        data.forEach { k,v in
//            jsvalue?.setObject(v, forKeyedSubscript: k as NSString)
//        }
        guard let json = try? data.toJSONString() else { return }
        context.setObject(json, forKeyedSubscript: "datalayer" as NSString)
        context.evaluateScript("""
    datalayer = JSON.parse(datalayer)
""")
    }
    
    func getDataLayer(context: JSContext) -> [String: Any] {
        guard let data = context.evaluateScript("JSON.stringify(datalayer)")?.toString().data(using: .utf8),
              let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dictionary
//        let value = context.evaluateScript("datalayer")
//
//        return value!.toDictionary2() ?? [String: Any]()
    }
}

extension JSValue {
    
    
    func clean() -> Any? {
        if self.isBoolean == true {
            return toBool()
        } else if isArray {
            return toArray2()
        } else if isObject {
            return toDictionary2()
        }
        return nil
    }
    
    func clean(key: String) -> Any? {
        guard self.hasProperty(key), let prop = self.forProperty(key) else { return nil }
        return prop.clean()
    }
    
    func toDictionary2() -> [String: Any]? {
        guard self.isObject else {
            return nil
        }
        var newDict: [String: Any] = self.toDictionary() as? [String: Any] ?? [String: Any]()
        let dictCopy = newDict
        dictCopy.forEach({ k,v in
            guard let value = clean(key: k) else { return }
            newDict[k] = value
        })
        return newDict
    }
    
    func toArray2() -> [Any]? {
        guard self.isArray, var array = self.toArray() else {
            return nil
        }
        for i in 0..<array.count {
            guard let cleaned = self.objectAtIndexedSubscript(i).clean() else {
                continue
            }
            array[i] = cleaned
        }
        return array
    }
}


public class NativeExtension: DispatchValidator {
    public var id: String = "NativeExtensions"
    var timings = [Int64]()
    public init() {
//        return;
        queue.asyncAfter(deadline: .now() + 15) {
            let time = self.timings
            var total: Int64 = 0
            for ms in time {
                total += ms
            }
            let result = total/Int64(time.count)
            print("EXTENSIONS Native average \(result) out of \(time.count) tests")
        }
    }
    public func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
//        return (true, nil)
        if let req = request as? TealiumTrackRequest {
            var dict = req.trackDictionary
            queue.async {
                self.runExtensions(data: &dict)
            }
        }
        return (true, nil)
    }
    
    public func shouldDrop(request: TealiumRequest) -> Bool {
        true
    }
    
    public func shouldPurge(request: TealiumRequest) -> Bool {
        true
    }
    
    func runExtensions(data: inout [String: Any]) {
        let start = Date()
        NSLog("EXTENSIONS Native START")
        for i in 1..<testCount {
            addKeyToContext(data: &data, key: "\(i)")
        }
        NSLog("EXTENSIONS Native Final data: \(data)")
        let end = Date().millisecondsFrom(earlierDate: start)
        timings.append(end)
        NSLog("EXTENSIONS Native END \(end)")
        
    }
    
    func addKeyToContext(data: inout [String: Any], key: String) {
        data[key] = key
    }
}
// swiftlint:enable all