//
//  TealiumTagManagement.swift
//
//  Created by Jason Koo on 12/14/16.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

import Foundation

enum TealiumTagManagementKey {
    static let dispatchService = "dispatch_service"
    static let estimatedProgress = "estimatedProgress"
    static let disable = "disable_tag_management"
    static let jsCommand = "js_command"
    static let jsResult = "js_result"
    static let maxQueueSize = "tagmanagement_queue_size"
    static let moduleName = "tagmanagement"
    static let responseHeader = "response_headers"
    static let overrideURL = "tagmanagement_override_url"
    static let payload = "payload"
}

enum TealiumTagManagementValue {
    static let defaultQueueSize = 100
}

enum TealiumTagManagementError : Error {
    case couldNotCreateURL
    case couldNotLoadURL
    case couldNotJSONEncodeData
    case webViewNotYetReady
}


extension TealiumConfig {
    
    func disableTagManagement() {
        
        optionalData[TealiumTagManagementKey.disable] = true
        
    }
  
    func setTagManagementQueueSize(to: Int) {

        optionalData[TealiumTagManagementKey.maxQueueSize] = to
        
    }
    
    func setTagManagementOverrideURL(string: String) {
        
        optionalData[TealiumTagManagementKey.overrideURL] = string
    }
    
}

// NOTE: UIWebview, the primary element of TealiumTagManagement can not run in XCTests.

#if TEST
#else
extension Tealium {
    
    public func tagManagement() -> TealiumTagManagement? {
        
        guard let module = modulesManager.getModule(forName: TealiumTagManagementKey.moduleName) as? TealiumTagManagementModule else {
            return nil
        }
        
        return module.tagManagement
        
    }
}
#endif

class TealiumTagManagementModule : TealiumModule {
    
    // Queue for staging calls to this dispatch service, as initial calls
    // likely to incoming before webView is ready.
    var queue = [TealiumTrack]()
    
    /// Overridable completion handler for module send command.
    var sendCompletion : (TealiumTagManagementModule, TealiumTrack) -> Void = { (_ module:TealiumTagManagementModule, _ track:TealiumTrack) in
    
        #if TEST
        #else
            // Default behavior
            module.tagManagement.track(track.data,
                       completion:{(success, info, error) in
                        
                let newTrack = TealiumTrack(data: track.data,
                                            info: info,
                                            completion: track.completion)
                if error != nil {
                    module.didFailToTrack(newTrack, error:error!)
                    return
                }
                module.didFinishTrack(newTrack)
                        
            })
        #endif
        
    }

    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumTagManagementKey.moduleName,
                                   priority: 1100,
                                   build: 1,
                                   enabled: true)
    }
    
    #if TEST
    #else
    var tagManagement = TealiumTagManagement()

    override func enable(config: TealiumConfig) {
    
        if config.optionalData[TealiumTagManagementKeys.disable] as? Bool == true {
            DispatchQueue.main.async {
                self.tagManagement.disable()
            }
            self.didFinishEnable(config:config)
            return
        }
    
        let account = config.account
        let profile = config.profile
        let environment = config.environment
        let overrideURL = config.optionalData[TealiumTagManagementKey.overrideURL] as? String
    
        DispatchQueue.main.async {

            self.tagManagement.internalDelegate = self
            if (overrideURL != nil) { self.tagManagement.urlString = overrideURL! }
            self.tagManagement.enable(forAccount: account,
                                 profile: profile,
                                 environment: environment,
                                 completion: {(success, error) in
            
                if success == false {
                    self.didFailToEnable(config: config,
                                    error: TealiumTagManagementError.couldNotLoadURL)
                    return
                }
                self.didFinishEnable(config: config)
                                    
            })
        }
        
    }

    override func disable() {
        
        DispatchQueue.main.async {

            self.tagManagement.disable()

        }
        didFinishDisable()
    }

    override func track(_ track: TealiumTrack) {

        DispatchQueue.main.async {
            
            self.addToQueue(track: track)
            
            if self.tagManagement.isWebViewReady() == false {
                // Not ready to send, move on.
                self.didFinishTrack(track)
                return
            }
            self.sendQueue()
        }

    }
    #endif

    
    // MARK: INTERNAL
    
    internal func addToQueue(track: TealiumTrack) {
        queue.append(track)
    }
    
    internal func sendQueue() {
        
        let queueCopy = queue
        
        for track in queueCopy{
        
            sendCompletion(self, track)
            
            queue.removeFirst()
        
        }
    
    }

}

#if TEST
#else
extension TealiumTagManagementModule : TealiumTagManagementDelegate {
    
    func tagManagementWebViewFinishedLoading() {
        
        DispatchQueue.main.async {
            
            self.sendQueue()
            
        }
    }
    
}
#endif
