//
//  MomentsAPIExtensions.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

extension TealiumConfigKey {
    static let momentsAPIRegion = "moments_api_region"
    static let momentsAPIReferer = "moments_api_referer"
}

public enum MomentsAPIRegion: String {
    case germany = "eu-central-1"
    case us_east = "us-east-1"
    case sydney = "ap-southeast-2"
    case oregon = "us-west-2"
    case tokyo = "ap-northeast-1"
    case hong_kong = "ap-east-1"
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
        private unowned var tealium: Tealium
        
        private var module: TealiumMomentsAPIModule? {
            (tealium.zz_internal_modulesManager?.modules.first {
                $0 is TealiumMomentsAPIModule
            }) as? TealiumMomentsAPIModule
        }
        
        /// Fetches a response from a configured Moments API Engine
        /// - Parameters:
        ///    - completion: `Result<EngineResponse, Error>` Optional completion block to be called when a response has been received from the Moments API
        ///         - result: `Result<EngineResponse, Error>` Result type to receive a valid Moments API Engine Response or an error
        public func fetchEngineResponse(engineID: String, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
            guard let module = module else {
                return
            }
            module.momentsAPI?.fetchEngineResponse(engineID: engineID, completion: completion)
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
