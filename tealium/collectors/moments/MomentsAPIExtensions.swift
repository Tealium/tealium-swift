//
//  MomentsAPIExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 16/04/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

extension TealiumConfigKey {
    static let momentsAPIRegion = "moments_api_region"
}

enum MomentsError: Error, LocalizedError {
    case missingRegion
    case missingVisitorID
    
    
    public var errorDescription: String? {
        switch self {
        case .missingRegion:
            return NSLocalizedString("Missing Region", comment: "Set momentsAPIRegion property on TealiumConfig.")
        case .missingVisitorID:
            return NSLocalizedString("Missing Visitor ID", comment: "Tealium Anonymous Visitor ID could not be determined. This is likely to be a temporary error, and should resolve itself.")
        }
    }
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
        ///    - completion: `Result<EngineResponse, Error>` Optional completion block to be called when a response has been received from the Adobe Visitor API
        ///         - result: `Result<EngineResponse, Error>` Result type to receive a valid Adobe Visitor or an error
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

    class MomentsWrapper {
        public var api: MomentsAPIWrapper?
        init(api: MomentsAPIWrapper? = nil) {
            self.api = api
        }
    }
    
    /// Provides API methods to interact with the Adobe Visitor API module
    var moments: MomentsWrapper? {
        return MomentsWrapper(api: MomentsAPIWrapper(tealium: self))
    }

}
