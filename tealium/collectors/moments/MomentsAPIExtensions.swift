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
    static let momentsAPIEngineID = "moments_api_engine_id"
    
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
    var momentsAPIEngineID: String? {
        get {
            options[TealiumConfigKey.momentsAPIEngineID] as? String
        }
        
        set {
            options[TealiumConfigKey.momentsAPIEngineID] = newValue
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
        
        /// Links a known visitor ID to an ECID
        /// - Parameters:
        ///    - knownId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
        ///    - authState: `AdobeVisitorAuthState?` the visitor's current authentication state
        ///    - completion: `AdobeVisitorCompletion` Optional completion block to be called when a response has been received from the Adobe Visitor API
        ///         - result: `Result<AdobeVisitor, Error>` Result type to receive a valid Adobe Visitor or an error
        public func fetchMoments(completion: @escaping (Result<[TealiumVisitorProfile], Error>) -> Void) {
            guard let module = module else {
                return
            }
            module.momentsAPI?.fetchMoments(completion: completion)
        }

        
        init(tealium: Tealium) {
            self.tealium = tealium
        }
    }
    
    /// Provides API methods to interact with the Adobe Visitor API module
    var adobeVisitorApi: MomentsAPIWrapper? {
        return MomentsAPIWrapper(tealium: self)
    }

}
