//
//  TealiumDatasourceModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/8/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumDatasourceKey {
    static let moduleName = "datasource"
    static let config = "com.tealium.datasource"
    static let variable = "tealium_datasource"
}

public extension TealiumConfig {

    convenience init(account: String,
                     profile: String,
                     environment: String,
                     datasource: String?) {
        self.init(account: account,
                  profile: profile,
                  environment: environment,
                  datasource: datasource,
                  optionalData: nil)

    }

    convenience init(account: String,
                     profile: String,
                     environment: String,
                     datasource: String?,
                     optionalData: [String: Any]?) {
        var newOptionalData = [String: Any]()
        if let initialOptionalData = optionalData {
            newOptionalData += initialOptionalData
        }
        if let initialDatasource = datasource {
            newOptionalData[TealiumDatasourceKey.config] = initialDatasource
        }
        self.init(account: account,
                  profile: profile,
                  environment: environment,
                  optionalData: newOptionalData)
    }

}

class TealiumDatasourceModule: TealiumModule {

    var datasource: String?

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDatasourceKey.moduleName,
                                   priority: 550,
                                   build: 3,
                                   enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true

        if let datasourceString = request.config.optionalData[TealiumDatasourceKey.config] as? String {
            datasource = datasourceString
        }

        didFinish(request)
    }

    override func track(_ track: TealiumTrackRequest) {

        guard let datasource = self.datasource else {
            didFinish(track)
            return
        }

        var newData: [String: Any] = [TealiumDatasourceKey.variable: datasource]
        newData += track.data
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)

        didFinish(newTrack)
    }

}
