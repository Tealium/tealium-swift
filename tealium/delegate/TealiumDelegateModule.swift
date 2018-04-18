//
//  TealiumDelegateModule.swift
//
//  Created by Jason Koo on 2/12/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TealiumDelegateKey {
    static let moduleName = "delegate"
    static let multicastDelegates = "com.tealium.delegate.delegates"
    static let completion = "com.tealium.delegate.completion"
}

public enum TealiumDelegateError: Error {
    case suppressedByShouldTrackDelegate
}

public typealias TealiumEnableCompletion = ((_ modulesResponses: [TealiumModuleResponse]) -> Void )

public protocol TealiumDelegate: class {

    func tealiumShouldTrack(data: [String: Any]) -> Bool
    func tealiumTrackCompleted(success: Bool, info: [String: Any]?, error: Error?)

}

public extension Tealium {

    convenience init(config: TealiumConfig,
                     completion: @escaping TealiumEnableCompletion ) {
        config.optionalData[TealiumDelegateKey.completion] = completion
        self.init(config: config)
    }

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
    var enableCompletion: TealiumEnableCompletion?

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

        if let completion = request.config.optionalData[TealiumDelegateKey.completion] as? TealiumEnableCompletion {
                enableCompletion = completion
        }

        didFinish(request)
    }

    override func handleReport(_  request: TealiumRequest) {
        if let request = request as? TealiumEnableRequest {
            enableCompletion?(request.moduleResponses)
        }
        if let request = request as? TealiumTrackRequest {
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

}

public class TealiumDelegates {

    var multicastDelegate = TealiumMulticastDelegate<TealiumDelegate>()

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
