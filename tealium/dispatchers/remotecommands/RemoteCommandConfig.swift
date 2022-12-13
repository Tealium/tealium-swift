//
//  RemoteCommandConfig.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public struct RemoteCommandConfig: Codable {
    var fileName: String? = ""
    var commandURL: URL?
    var apiConfig: [String: Any]?
    var mappings: [String: String]?
    var apiCommands: [String: String]?
    var statics: [String: Any]?
    var lastFetch: Date?

    public init(config: [String: Any],
                mappings: [String: String],
                apiCommands: [String: String],
                statics: [String: Any],
                commandName: String?,
                commandURL: URL?) {
        self.apiConfig = config
        self.mappings = mappings
        self.apiCommands = apiCommands
        self.statics = statics
        self.fileName = commandName
        self.commandURL = commandURL
    }

    enum CodingKeys: String, CodingKey {
        case fileName
        case apiConfig = "config"
        case mappings
        case apiCommands = "commands"
        case statics
        case lastFetch
        case commandURL
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileName, forKey: .fileName)

        if let apiConfig = apiConfig?.codable {
            try container.encode(apiConfig, forKey: .apiConfig)
        }
        if let statics = statics?.codable {
            try container.encode(statics, forKey: .statics)
        }

        try container.encode(mappings, forKey: .mappings)
        try container.encode(apiCommands, forKey: .apiCommands)
        try container.encode(lastFetch, forKey: .lastFetch)
        try container.encode(commandURL, forKey: .commandURL)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try values.decodeIfPresent(AnyDecodable.self, forKey: .apiConfig)
        let decodableStatics = try values.decodeIfPresent(AnyDecodable.self, forKey: .statics)
        fileName = try values.decodeIfPresent(String.self, forKey: .fileName)
        apiConfig = decoded?.value as? [String: Any]
        statics = decodableStatics?.value as? [String: Any]
        mappings = try values.decodeIfPresent([String: String].self, forKey: .mappings)
        apiCommands = try values.decodeIfPresent([String: String].self, forKey: .apiCommands)
        lastFetch = try values.decodeIfPresent(Date.self, forKey: .lastFetch) ?? Date()
        commandURL = try values.decodeIfPresent(URL.self, forKey: .commandURL)
    }

    public init?(file name: String, _ logger: TealiumLoggerProtocol?, _ bundle: Bundle?) {

        let decoder = JSONDecoder()
        do {
            guard let path = (bundle ?? Bundle.main).path(forResource: name, ofType: "json") else {
                return nil
            }
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let config = try decoder.decode(RemoteCommandConfig.self, from: jsonData)
            self.apiCommands = config.apiCommands
            self.apiConfig = config.apiConfig
            self.mappings = config.mappings
            self.statics = config.statics
        } catch {
            logger?.log(TealiumLogRequest(title: "Remote Commands",
                                          message: "Error while trying to process remote command config: \(error.localizedDescription)",
                                          info: nil,
                                          logLevel: .error,
                                          category: .general))
        }
    }

}
#endif
