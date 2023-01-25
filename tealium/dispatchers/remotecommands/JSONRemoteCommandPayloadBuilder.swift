//
//  JSONRemoteCommandPayloadBuilder.swift
//  TealiumRemoteCommands
//
//  Created by Enrico Zannini on 23/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

class JSONRemoteCommandPayloadBuilder {

    /// Maps the track call data to the mappings and command names provided in the JSON file
    ///
    /// - Parameters:
    ///   - trackData: `[String: Any]` payload sent in the the track call
    ///   - commandConfig: `RemoteCommandConfig`decoded data loaded from the file name/url provided during initialization of the JSON command
    ///   - Returns: `[String: Any]` vendor specific data
    class func process(trackData: [String: Any], commandConfig: RemoteCommandConfig, completion: ModuleCompletion?) -> [String: Any]? {
        guard let mappings = commandConfig.mappings else {
            completion?((.failure(TealiumRemoteCommandsError.mappingsNotFound), nil))
            return nil
        }
        let payload = payloadWithStatics(trackData: trackData, statics: commandConfig.statics)
        var mapped = objectMap(payload: payload, lookup: mappings)
        guard let commandNames = commandConfig.apiCommands else {
            completion?((.failure(TealiumRemoteCommandsError.commandsNotFound), nil))
            return nil
        }
        guard let commandName = extractCommandName(trackData: trackData, commandNames: commandNames) else {
            completion?((.failure(TealiumRemoteCommandsError.commandNameNotFound), nil))
            return nil
        }
        mapped[RemoteCommandsKey.commandName] = commandName
        if let config = commandConfig.apiConfig {
            mapped.merge(config) { _, second in second }
        }
        return mapped
    }

    class func splitKeysAndValuesToMatch(_ key: String) -> [(String, String)] {
        return key.split(separator: ",")
            .map { subKey in
                var split = subKey.split(separator: ":").map { String($0) }
                if split.count == 1 {
                    split.insert(TealiumDataKey.event, at: 0)
                }
                return (split[0], split[1])
            }
    }

    class func payloadWithStatics(trackData: [String: Any], statics: [String: Any]?) -> [String: Any] {
        guard let statics = statics else { return trackData }
        var payload = trackData
        for staticKey in statics.keys {
            if compoundKey(staticKey, matchesTrackData: payload),
               let staticsMap = statics[staticKey] as? [String: Any] {
                payload += staticsMap
            }
        }
        return payload
    }

    /// returns: true if all the keys and value match the trackData
    class func keysAndValues(_ keysAndValues: [(String, String)], matchTrackData trackData: [String: Any]) -> Bool {
        let firstNonMatchingPair = keysAndValues.first { key, value in
            guard let payloadValue = trackData[key] else {
                return true
            }
            guard let valueString = payloadValue as? String else {
                return String(describing: payloadValue) != value
            }
            return valueString != value
        }
        return firstNonMatchingPair == nil // True if all the pairs match
    }

    /**
     * Returns true if the tealium_event in the trackData matches the whole compoundKey as is or if all key:values (separated by comma) match the respective values in the trackData.
     *
     * Example:
     * With the key "abc:def,123:456" this method will return true if trackData contains:
     * ["tealium_event": "abc:def,123:456"] (to prevent breaking previous implementations)
     * or if it contains:
     * ["abc": "def", "123": "456"]
     */
    class func compoundKey(_ compoundKey: String, matchesTrackData trackData: [String: Any]) -> Bool {
        keysAndValues([(TealiumDataKey.event, compoundKey)], matchTrackData: trackData) // previous behavior
        || keysAndValues(splitKeysAndValuesToMatch(compoundKey), matchTrackData: trackData)
    }

    class func extractCommandName(trackData: [String: Any], commandNames: [String: String]) -> String? {
        var commands = [String]()
        for commandKey in commandNames.keys {
            if compoundKey(commandKey, matchesTrackData: trackData),
               let commandName = commandNames[commandKey] {
                commands.append(commandName)
            }
        }

        if var eventType = trackData[TealiumDataKey.eventType] as? String {
            if eventType != TealiumTrackType.view.rawValue {
                eventType = TealiumTrackType.event.rawValue // Some events change this for utag.js
            }
            if let commandName = commandNames["all_\(eventType)s"] {
                commands.append(commandName)
            }
        }
        if commands.count > 0 {
            return commands.joined(separator: ",")
        } else {
            return nil
        }
    }

    /// Maps the payload recieved from a tracking call to the data specific to the third party
    /// vendor specified for the remote command. A lookup dictionary is used to determine the
    /// mapping.
    /// - Parameter payload: `[String: Any]` from tracking call
    /// - Parameter self: `[String: String]` `mappings` key from JSON file definition
    /// - Returns: `[String: Any]` mapped key value pairs for specific remote command vendor
    class func mapPayload(_ payload: [String: Any], lookup: [String: String]) -> [String: Any] {
        return lookup.reduce(into: [String: Any]()) { result, tuple in
            let values = tuple.value.split(separator: ",")
                .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            if let payload = payload[tuple.key] {
                values.forEach {
                    result[$0] = payload
                }
            }
        }
    }

    /// Performs mapping then splits any keys with a `.` present and creates a nested object
    /// from those keys using the `parseKeys()` method. If no keys with `.` are present,
    ///  performs mapping as normal using the `mapPayload()` method.
    /// - Parameter payload: `[String: Any]` from track method
    /// - Returns: `[String: Any]` mapped key value pairs for specific remote command vendor
    class func objectMap(payload: [String: Any], lookup: [String: String]) -> [String: Any] {
        let nestedMapped = mapPayload(payload, lookup: lookup)
        if nestedMapped.keys.filter({ $0.contains(".") }).count > 0 {
            var output = nestedMapped.filter({ !$0.key.contains(".") })
            let keysToParse = nestedMapped.filter { $0.key.contains(".") }
            _ = output += parseKeys(from: keysToParse)
            return output
        }
        return nestedMapped
    }

    /// Splits any keys with a `.` present and creates a nested object from those keys.
    /// e.g. if the key in the JSON was `event.parameter`, an object would be created
    /// like so: ["event": "parameter": "valueFromTrack"].
    /// - Returns: `[String: [String: Any]]` containing the new nested objects
    class func parseKeys(from payload: [String: Any]) -> [String: [String: Any]] {
        return payload.reduce(into: [String: [String: Any]]()) { result, dictionary in
            let key = String(dictionary.key.split(separator: ".")[0])
            let value = String(dictionary.key.split(separator: ".")[1])
            if result[key] == nil {
                result[key] = [value: dictionary.value]
            } else if var resultValue = result[key] {
                resultValue[value] = dictionary.value
                result[key] = resultValue
            }
        }
    }
}
#endif
