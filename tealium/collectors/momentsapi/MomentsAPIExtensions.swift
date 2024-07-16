//
//  MomentsAPIExtensions.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
#if momentsapi
import TealiumCore
#endif

extension TealiumConfigKey {
    static let momentsAPIRegion = "moments_api_region"
    static let momentsAPIReferer = "moments_api_referer"
}

public enum MomentsAPIRegion {
    // swiftlint:disable identifier_name
    case germany
    case us_east
    case sydney
    case oregon
    case tokyo
    case hong_kong
    case custom(String)

    var rawValue: String {
        switch self {
        case .germany:
            return "eu-central-1"
        case .us_east:
            return "us-east-1"
        case .sydney:
            return "ap-southeast-2"
        case .oregon:
            return "us-west-2"
        case .tokyo:
            return "ap-northeast-1"
        case .hong_kong:
            return "ap-east-1"
        case .custom(let regionString):
            return regionString
        }
    }
    // swiftlint:enable identifier_name
}

public extension TealiumConfig {

    /// Sets the region for calls to the Moments API endpoint
    var momentsAPIRegion: MomentsAPIRegion? {
        get {
            options[TealiumConfigKey.momentsAPIRegion] as? MomentsAPIRegion
        }

        set {
            options[TealiumConfigKey.momentsAPIRegion] = newValue
        }
    }

    /// Sets the region for calls to the Moments API endpoint
    var momentsAPIReferer: String? {
        get {
            options[TealiumConfigKey.momentsAPIReferer] as? String
        }

        set {
            options[TealiumConfigKey.momentsAPIReferer] = newValue
        }
    }
}

public extension Tealium {

    class MomentsAPIWrapper {
        private weak var tealium: Tealium?

        private var module: TealiumMomentsAPIModule? {
            (tealium?.zz_internal_modulesManager?.modules.first {
                $0 is TealiumMomentsAPIModule
            }) as? TealiumMomentsAPIModule
        }

        /// Fetches a response from a configured Moments API Engine
        /// - Parameters:
        ///    - completion: `Result<EngineResponse, Error>` Optional completion block to be called when a response has been received from the Moments API
        ///         - result: `Result<EngineResponse, Error>` Result type to receive a valid Moments API Engine Response or an error
        public func fetchEngineResponse(engineID: String, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
            TealiumQueues.backgroundSerialQueue.async(qos: .userInitiated) {
                guard let module = self.module else {
                    return
                }
                module.momentsAPI?.fetchEngineResponse(engineID: engineID, completion: completion)
            }
        }

        init(tealium: Tealium) {
            self.tealium = tealium
        }
    }

    /// Provides API methods to interact with the Moments module
    var momentsAPI: MomentsAPIWrapper? {
        return MomentsAPIWrapper(tealium: self)
    }

}
