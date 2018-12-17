//
//  TealiumDelegateModule.swift
//  tealium-swift
//
//  Created by Craig Rouse on 2/12/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if delegate
import TealiumCore
#endif

public enum TealiumDelegateKey {
    static let moduleName = "delegate"
    static let multicastDelegates = "com.tealium.delegate.delegates"
}

public enum TealiumDelegateError: Error {
    case suppressedByShouldTrackDelegate
}

enum TealiumDelegateConstants {
    static let maxAttempts = 20
    static let interval = 0.2
}

public protocol TealiumDelegate: class {

    func tealiumShouldTrack(data: [String: Any]) -> Bool
    func tealiumTrackCompleted(success: Bool, info: [String: Any]?, error: Error?)

}

public extension Tealium {
    func delegates() -> TealiumDelegates? {
        guard let module = modulesManager.getModule(forName: TealiumDelegateKey.moduleName) as? TealiumDelegateModule else {
            return nil
        }

        return module.delegates
    }

}

public extension TealiumConfig {

    func delegates() -> TealiumDelegates {
        if let delegates = self.optionalData[TealiumDelegateKey.multicastDelegates] as? TealiumDelegates {
            return delegates
        }

        // Default
        return TealiumDelegates()
    }

    func addDelegate(_ delegate: TealiumDelegate) {
        let delegates = self.delegates()

        delegates.add(delegate: delegate)

        self.optionalData[TealiumDelegateKey.multicastDelegates] = delegates
    }

}

class TealiumDelegateModule: TealiumModule {

    var delegates: TealiumDelegates?

    override class  func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDelegateKey.moduleName,
                                   priority: 900,
                                   build: 4,
                                   enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true

        delegates = request.config.delegates()
        delegate?.tealiumModuleRequests(module: self,
                                        process: TealiumReportNotificationsRequest())

        didFinish(request)
    }

    override func handleReport(_  request: TealiumRequest) {
        if let request = request as? TealiumEnableRequest {
            runEnableCompletion(request, runs: nil)
        } else if let request = request as? TealiumTrackRequest {
            delegates?.invokeTrackCompleted(forTrackProcess: request)
        }
    }

    override func disable(_ request: TealiumDisableRequest) {
        delegates?.removeAll()
        delegates = nil
        didFinish(request)
    }

    override func track(_ track: TealiumTrackRequest) {
        if delegates?.invokeShouldTrack(data: track.data) == false {
            // Suppress the event from further processing
            track.completion?(false, nil, TealiumDelegateError.suppressedByShouldTrackDelegate)
            didFailToFinish(track,
                            error: TealiumDelegateError.suppressedByShouldTrackDelegate)
            return
        }
        didFinish(track)
    }

    func getTealiumInstanceFromConfig(_ config: TealiumConfig) -> Tealium? {
        let instanceKey = "\(config.account).\(config.profile).\(config.environment)"
        return TealiumInstanceManager.shared.getInstanceByName(instanceKey)
    }

    func runEnableCompletion(_ request: TealiumEnableRequest, runs: Int?) {
        let config = request.config
        let runs = runs ?? 0
        // under some circumstances, competion would run before Tealium is initialized
        // this guarantees Tealium instance is not nil before calling completion
        if let _ = getTealiumInstanceFromConfig(config) {
            request.enableCompletion?(request.moduleResponses)
        } else if runs < TealiumDelegateConstants.maxAttempts {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + TealiumDelegateConstants.interval) {
                self.runEnableCompletion(request, runs: runs + 1)
            }
        }
    }

}

public class TealiumDelegates {
    // swiftlint:disable weak_delegate
    var multicastDelegate = TealiumMulticastDelegate<TealiumDelegate>()
    // swiftlint:enable weak_delegate

    /// Add a weak pointer to a class conforming to the TealiumDelegate protocol.
    ///
    /// - Parameter delegate: Class conforming to the TealiumDelegate protocols.
    public func add(delegate: TealiumDelegate) {
        multicastDelegate.add(delegate)
    }

    /// Remove the weaker pointer reference to a given class from the multicast
    ///   delegates handler.
    ///
    /// - Parameter delegate: Class conforming to the TealiumDelegate protocols.
    public func remove(delegate: TealiumDelegate) {
        multicastDelegate.remove(delegate)
    }

    /// Remove all weak pointer references to classes conforming to the TealiumDelegate
    ///   protocols from the multicast delgate handler.
    public func removeAll() {
        multicastDelegate.removeAll()
    }

    /// Query all delegates if the data should be tracked or suppressed.
    ///
    /// - Parameter data: Data payload to inspect
    /// - Returns: True if all delegates approve
    public func invokeShouldTrack(data: [String: Any]) -> Bool {
        var shouldTrack = true
        multicastDelegate.invoke { if $0.tealiumShouldTrack(data: data) == false {
                shouldTrack = false
            }
        }

        return shouldTrack
    }

    /// Inform all delegates that a track call has completed.
    ///
    /// - Parameter forTrackProcess: TealiumRequest that was completed
    public func invokeTrackCompleted(forTrackProcess: TealiumTrackRequest) {

        for response in forTrackProcess.moduleResponses {
            let success = response.success
            let error = response.error
            let info = response.info

            multicastDelegate.invoke { $0.tealiumTrackCompleted(success: success, info: info, error: error) }
        }

    }
}

// Convenience += and -= operators for adding/removing delegates
public func += <T: TealiumDelegate> (left: TealiumDelegates, right: T) {
    left.add(delegate: right)
}

public func -= <T: TealiumDelegate> (left: TealiumDelegates, right: T) {
    left.remove(delegate: right)
}
