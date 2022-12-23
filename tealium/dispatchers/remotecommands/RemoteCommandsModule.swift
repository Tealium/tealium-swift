//
//  RemoteCommandsModule.swift
//  tealium-swift
//
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

import StoreKit

enum ConversionConstants {
    static let commandId = "conversioncommand"
    static let description = "Conversion Remote Command"
    static let commandName = "command_name"
    static let version = "1.0.0"
    static let seperator: Character = ","

    struct Commands {
        static let registerAppForAttribution = "registerappforattribution"
        static let setConversionBit = "setconversionbit"
        static let resetConversionBit = "resetconversionbit"
        static let setConversionValue = "setconversionvalue"
    }

    struct EventKeys {
        static let fineValue = "fine_value"
        static let coarseValue = "coarse_value"
        static let bitNumber = "bit_number"
        static let lockWindow = "lock_window"

    }
}

public protocol ConversionDelegate: AnyObject {
    func onConversionUpdate(conversionData: ConversionData)
    func onConversionUpdateCompleted(error: Error?)
}

public struct ConversionData: Codable {
    public enum CoarseValue: String, Codable {
        case high
        case medium
        case low

        @available(iOS 16.0, *)
        var toSKAdValue: SKAdNetwork.CoarseConversionValue {
            switch self {
            case .high: return .high
            case .medium: return .medium
            case .low: return .low
            }
        }
    }
    internal(set) public var fineValue: Int
    internal(set) public var coarseValue: CoarseValue?
    internal(set) public var lockWindow: Bool = false
}

@available(iOS 11.3, *)
extension UserDefaults {
    private var key: String { "Tealium.RemoteCommands.fineConversionValue" }
    var fineConversionValue: Int {
        get {
            guard let data = self.data(forKey: key),
                  let conversionData = try? JSONDecoder().decode(Int.self, from: data) else {
                return 0
            }
            return conversionData
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            self.set(data, forKey: key)
        }
    }
}

@available(iOS 11.3, *)
public class ConversionRemoteCommand: RemoteCommand {
    override public var version: String? { ConversionConstants.version }
    public weak var conversionDelegate: ConversionDelegate?
    let userDefaults: UserDefaults
    var fineValue = 0
    public init(type: RemoteCommandType, delegate: ConversionDelegate) {
        conversionDelegate = delegate
        let defaults = UserDefaults(suiteName: "Tealium.RemoteCommands") ?? .standard
        self.userDefaults = defaults
        fineValue = defaults.fineConversionValue
        weak var weakSelf: ConversionRemoteCommand?
        super.init(commandId: ConversionConstants.commandId, description: ConversionConstants.description, type: type) { response in
            print(response)
            guard let self = weakSelf,
                  let payload = response.payload else {
                return
            }
            self.handleCompletion(payload: payload)
        }
        weakSelf = self
    }

    func handleCompletion(payload: [String: Any]) {
        guard let commandIdString = payload[ConversionConstants.commandName] as? String else {
            return
        }
        let commands = commandIdString.split(separator: ConversionConstants.seperator)
        guard commands.count > 0 else { return }
        var conversionData = ConversionData(fineValue: fineValue)
        commands.forEach { command in
            handleCommand(String(command), payload: payload, conversionData: &conversionData)
        }
        storeConversionData()
        updatePostbackConversionValue(conversionData: conversionData)
        conversionDelegate?.onConversionUpdate(conversionData: conversionData)
    }

    func updateConversionData(_ conversionData: inout ConversionData, fineValue: Int, payload: [String: Any]) {
        conversionData.fineValue = fineValue
        if let coarseValueString = payload[ConversionConstants.EventKeys.coarseValue] as? String,
              let coarseValue = ConversionData.CoarseValue(rawValue: coarseValueString) {
            conversionData.coarseValue = coarseValue
        }
        if let lockWindow = payload[ConversionConstants.EventKeys.lockWindow] as? Bool {
            conversionData.lockWindow = lockWindow
        }
    }

    func handleCommand(_ commandId: String, payload: [String: Any], conversionData: inout ConversionData) {
        switch commandId {
        case ConversionConstants.Commands.setConversionBit:
            guard let bitNumber = getBitNumber(payload: payload) else { return }
            updateConversionData(&conversionData,
                                 fineValue: conversionData.fineValue | (1 << bitNumber),
                                 payload: payload)
        case ConversionConstants.Commands.resetConversionBit:
            guard let bitNumber = getBitNumber(payload: payload) else { return }
            updateConversionData(&conversionData,
                                 fineValue: conversionData.fineValue & ~(1 << bitNumber),
                                 payload: payload)
        case ConversionConstants.Commands.setConversionValue:
            guard let fineValue = payload[ConversionConstants.EventKeys.fineValue] as? Int,
                  fineValue >= 0, fineValue < 64 else {
                return
            }
            updateConversionData(&conversionData,
                                 fineValue: fineValue,
                                 payload: payload)
        case ConversionConstants.Commands.registerAppForAttribution:
            if #unavailable(iOS 14.0) {
                SKAdNetwork.registerAppForAdNetworkAttribution()
            }
        default:
            break
        }
    }

    func getBitNumber(payload: [String: Any]) -> Int? {
        guard let bitNumber = payload[ConversionConstants.EventKeys.bitNumber] as? Int,
            bitNumber >= 0, bitNumber < 6 else {
            return nil
        }
        return bitNumber
    }

    func updatePostbackConversionValue(conversionData: ConversionData) {
        if #available(iOS 15.4, *) {
            let completion = self.conversionDelegate?.onConversionUpdateCompleted(error:)
            if #available(iOS 16.1, *), let coarseValue = conversionData.coarseValue?.toSKAdValue {
                    SKAdNetwork.updatePostbackConversionValue(conversionData.fineValue,
                                                              coarseValue: coarseValue,
                                                              lockWindow: conversionData.lockWindow,
                                                              completionHandler: completion)
            } else {
                SKAdNetwork.updatePostbackConversionValue(conversionData.fineValue, completionHandler: completion)
            }
        } else if #available(iOS 14.0, *) {
            SKAdNetwork.updateConversionValue(conversionData.fineValue)
        }
    }

    func storeConversionData() {
        userDefaults.fineConversionValue = fineValue
    }
}

public class RemoteCommandsModule: Dispatcher {

    public var id: String = ModuleNames.remotecommands
    public var config: TealiumConfig
    public var isReady: Bool = false
    public var remoteCommands: RemoteCommandsManagerProtocol
    var reservedCommandsAdded = false
    let disposeBag = TealiumDisposeBag()

    /// Provided for unit testing￼.
    ///
    /// - Parameter remoteCommands: Class instance conforming to `RemoteCommandsManagerProtocol`
    convenience init (context: TealiumContext,
                      delegate: ModuleDelegate,
                      remoteCommands: RemoteCommandsManagerProtocol? = nil) {
        self.init(context: context, delegate: delegate) { _ in }
        self.remoteCommands = remoteCommands ?? self.remoteCommands
    }

    /// Initializes the module
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    public required init(context: TealiumContext, delegate: ModuleDelegate, completion: ModuleCompletion?) {
        self.config = context.config
        remoteCommands = RemoteCommandsManager(config: config, delegate: delegate)
        updateReservedCommands(config: config)
        addCommands(from: config)
        remoteCommands.onCommandsChanged.subscribe { commands in
            let data = [TealiumDataKey.remoteCommands: commands.map { $0.nameAndVersion }]
            context.dataLayer?.add(data: data,
                                   expiry: Expiry.untilRestart)
        }.toDisposeBag(disposeBag)
    }

    /// Allows Remote Commands to be added from the TealiumConfig object.
    /// ￼
    /// - Parameter config: `TealiumConfig` object containing Remote Commands
    private func addCommands(from config: TealiumConfig) {
        if let commands = config.remoteCommands {
            for command in commands {
                self.remoteCommands.add(command)
            }
        }
    }

    /// Identifies if any built-in Remote Commands should be disabled.
    /// ￼
    /// - Parameter config: `TealiumConfig` object containing flags indicating which built-in commands should be disabled.
    func updateReservedCommands(config: TealiumConfig) {
        guard reservedCommandsAdded == false else {
            return
        }
        var shouldDisable = false
        if let shouldDisableSetting = config.options[TealiumConfigKey.disableHTTP] as? Bool {
            shouldDisable = shouldDisableSetting
        }
        if shouldDisable == true {
            remoteCommands.remove(commandWithId: RemoteCommandsKey.commandId)
        } else if remoteCommands.webviewCommands[RemoteCommandsKey.commandId] == nil {
            let httpCommand = RemoteHTTPCommand.create(with: remoteCommands.moduleDelegate, urlSession: remoteCommands.urlSession )
            remoteCommands.add(httpCommand)
        }
        reservedCommandsAdded = true
    }

    public func dynamicTrack(_ request: TealiumRequest,
                             completion: ModuleCompletion?) {
        switch request {
        case let request as TealiumRemoteCommandRequest:
            self.remoteCommands.trigger(command: .webview,
                                        with: request.data,
                                        completion: completion)
        case let request as TealiumRemoteAPIRequest:
            self.remoteCommands.jsonCommands.forEach { command in
                guard let config = command.config,
                      let url = config.commandURL,
                      let name = config.fileName
                else {
                    return
                }
                self.remoteCommands.refresh(command,
                                            url: url,
                                            file: name)
            }
            self.remoteCommands.trigger(command: .JSON,
                                        with: request.trackRequest.trackDictionary,
                                        completion: completion)
        default:
            break
        }

    }
}
#endif
