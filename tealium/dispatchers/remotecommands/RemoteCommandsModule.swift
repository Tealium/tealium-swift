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
    internal(set) public var value: Int
    internal(set) public var coarseValue: CoarseValue = .low
    internal(set) public var lockWindow: Bool = false
}

@available(iOS 11.3, *)
extension UserDefaults {
    private var key: String { "Tealium.RemoteCommands.conversionData" }
    var conversionData: ConversionData? {
        get {
            guard let data = self.data(forKey: key),
                  let conversionData = try? JSONDecoder().decode(ConversionData.self, from: data) else {
                return nil
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
    public weak var conversionDelegate: ConversionDelegate?
    let userDefaults: UserDefaults
    var conversionData: ConversionData
    public init(type: RemoteCommandType, delegate: ConversionDelegate) {
        conversionDelegate = delegate
        let defaults = UserDefaults(suiteName: "Tealium.RemoteCommands") ?? .standard
        self.userDefaults = defaults
        conversionData = defaults.conversionData ?? ConversionData(value: 0)
        weak var weakSelf: ConversionRemoteCommand?
        super.init(commandId: "ConversionCommand", description: "Conversion Value Mapping for SKADNetwork", type: type) { response in
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
        guard let commandIdString = payload["command_name"] as? String else {
            return
        }
        let commands = commandIdString.split(separator: ",")
        guard commands.count > 0 else { return }
        commands.forEach { command in
            handleCommand(String(command), payload: payload)
        }
        storeConversionData()
        updatePostbackConversionValue()
        conversionDelegate?.onConversionUpdate(conversionData: conversionData)
    }

    func handleCommand(_ commandId: String, payload: [String: Any]) {
        switch commandId {
        case "setconversionbit":
            guard let bitNumber = getBitNumber(payload: payload) else { return }
            self.conversionData.value |= (1 << bitNumber)
        case "resetconversionbit":
            guard let bitNumber = getBitNumber(payload: payload) else { return }
            self.conversionData.value &= ~(1 << bitNumber)
        case "setconversionvalue":
            guard let conversionValue = payload["conversion_value"] as? Int,
                  conversionValue >= 0, conversionValue < 64 else {
                return
            }
            self.conversionData.value = conversionValue
        case "setcoarsevalue":
            guard let coarseValueString = payload["coarse_value"] as? String,
                  let coarseValue = ConversionData.CoarseValue(rawValue: coarseValueString) else {
                return
            }
            self.conversionData.coarseValue = coarseValue
        case "setlockwindow":
            guard let lockWindow = payload["lock_window"] as? Bool else {
                return
            }
            self.conversionData.lockWindow = lockWindow
        case "registerappforadnetworkattribution":
            if #unavailable(iOS 14.0) {
                SKAdNetwork.registerAppForAdNetworkAttribution()
            }
        default:
            break
        }
    }

    func getBitNumber(payload: [String: Any]) -> Int? {
        guard let bitNumber = payload["bit_number"] as? Int,
            bitNumber >= 0, bitNumber < 6 else {
            return nil
        }
        return bitNumber
    }

    func updatePostbackConversionValue() {
        let completion = self.conversionDelegate?.onConversionUpdateCompleted(error:)
        if #available(iOS 16.1, *) {
            SKAdNetwork.updatePostbackConversionValue(conversionData.value,
                                                      coarseValue: conversionData.coarseValue.toSKAdValue,
                                                      lockWindow: conversionData.lockWindow,
                                                      completionHandler: completion)
        } else if #available(iOS 15.4, *) {
            SKAdNetwork.updatePostbackConversionValue(conversionData.value, completionHandler: completion)
        } else if #available(iOS 14.0, *) {
            SKAdNetwork.updateConversionValue(conversionData.value)
        }
    }

    func storeConversionData() {
        userDefaults.conversionData = conversionData
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
            self.remoteCommands.trigger(command: .webview, with: request.data, completion: completion)
        case let request as TealiumRemoteAPIRequest:
            self.remoteCommands.jsonCommands.forEach { command in
                guard let config = command.config,
                      let url = config.commandURL,
                      let name = config.fileName
                else {
                    return
                }
                self.remoteCommands.refresh(command, url: url, file: name)
            }
            self.remoteCommands.trigger(command: .JSON, with: request.trackRequest.trackDictionary, completion: completion)
        default:
            break
        }

    }
}
#endif
