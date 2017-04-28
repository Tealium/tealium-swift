//
//  TealiumLoggerModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

extension Tealium {
    
    public func logger() -> TealiumLogger? {
        
        guard let module = modulesManager.getModule(forName: TealiumLoggerKey.moduleName) as? TealiumLoggerModule else {
            return nil
        }
        
        return module.logger
        
    }
    
}

extension TealiumConfig {
    
    @available(*, deprecated, message: "Use the Tealium.logger().getLogLevel() API instead.")
    func getLogLevel() -> LogLevel {
        
        // Stub - Config can no longer access log levels.
        return .none
        
    }
    
    @available(*, deprecated, message: "Use the Tealium.logger().setLogLevel() API instead.")
    func setLogLevel(logLevel: LogLevel) {
        
        // Do nothing - Config can no longer manipulate log levels.
        
    }
    
}


/// Module for adding basic console log output.
class TealiumLoggerModule : TealiumModule {
    
    var logger : TealiumLogger?

    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumLoggerKey.moduleName,
                                   priority: 100,
                                   build: 3,
                                   enabled: true)
    }
    
    override func enable(config:TealiumConfig) {
        
        if logger == nil {

            let id = "\(config.account):\(config.profile):\(config.environment)"
        
            logger = TealiumLogger(loggerId: id, logLevel: .verbose)
        }
        
        didFinishEnable(config: config)

    }
    
    override func disable() {
        
        logger = nil
        
        didFinishDisable()

    }
    
    override func handleReport(fromModule: TealiumModule,
                               process: TealiumProcess) {
        
        switch process.type {
        case .enable:
            let message = process.successful == true ? "ENABLED" : "FAILED TO ENABLE"
            logWithPrefix(fromModule: fromModule,
                          message: message,
                          logLevel: .verbose)
        case .disable:
            let message = process.successful == true ? "DISABLED" : "FAILED TO DISABLE"
            logWithPrefix(fromModule: fromModule,
                          message: message,
                          logLevel: .verbose)
        case .track:
            if process.successful == false {
                let message = "FAILED TRACK: \(String(describing: process.track?.data)) \(String(describing: process.error))"
                logWithPrefix(fromModule: fromModule,
                              message: message,
                              logLevel: .warnings)
            }

        }
        
        guard let error = process.error else {
            didFinishReport(fromModule: fromModule,
                            process: process)
            return
        }
        
        logWithPrefix(fromModule: fromModule,
                      message: error.localizedDescription,
                      logLevel: .errors)
        
        didFinishReport(fromModule: fromModule,
                        process: process)
        
    }
    
    func logWithPrefix(fromModule: TealiumModule,
                       message: String,
                       logLevel: LogLevel) {
        
        let moduleConfig = fromModule.moduleConfig()
        let newMessage = "\(moduleConfig.name) module.\(moduleConfig.build): \(message)"
        let _ = logger?.log(message: newMessage, logLevel: logLevel)
        
    }
    
}
