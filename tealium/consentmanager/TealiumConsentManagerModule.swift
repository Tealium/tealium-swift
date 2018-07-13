//
//  TealiumConsentManagerModule.swift
//  tealium-swift
//
//  Created by Craig Rouse on 29/03/2018.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumConsentManagerModule: TealiumModule {

    let consentManager = TealiumConsentManager()
    var ready: Bool = false

    override class func moduleConfig() -> TealiumModuleConfig {
        return  TealiumModuleConfig(name: TealiumConsentConstants.moduleName,
                priority: 50,
                build: 2,
                enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        // start consent manager with completion block
        consentManager.start(config: request.config, delegate: delegate) {
            self.ready = true
            self.releaseQueue()
            self.didFinish(request)
        }
        consentManager.addConsentDelegate(self)
    }

    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        didFinish(request)
    }

    override func track(_ track: TealiumTrackRequest) {
        // do nothing if disabled - return to normal operation
        if self.isEnabled == false {
            didFinish(track)
            return
        }

        // allow tracking calls to continue if they are for auditing purposes
        if let event = track.data[TealiumKey.event] as? String, (event == TealiumConsentConstants.consentPartialEventName
                || event == TealiumConsentConstants.consentGrantedEventName || event == TealiumConsentConstants.consentDeclinedEventName || event == TealiumConsentConstants.updateConsentCookieEventName) {
            didFinishWithNoResponse(track)
            return
        }
        // append consent data to each tracking request
        let newTrack = addConsentDataToTrack(track)

        // if not ready yet, queue requests
        if !self.ready {
            queue(newTrack)
            let report = TealiumReportRequest(message: "Consent Manager: Queued track. Consent Manager not ready.")
            delegate?.tealiumModuleRequests(module: self,
                    process: report)
            return
        }

        // check if tracking is allowed
        switch consentManager.getTrackingStatus() {
        case .trackingQueued:
            queue(newTrack)
            consentManager.willQueueTrackingCall(newTrack)
                // yes, user has allowed tracking
        case .trackingAllowed:
            consentManager.willSendTrackingCall(newTrack)
            didFinishWithNoResponse(newTrack)
                // user declined tracking. we will discard this request
        case .trackingForbidden:
            self.purgeQueue()
            consentManager.willDropTrackingCall(newTrack)
            return
        }
    }

    func addConsentDataToTrack(_ track: TealiumTrackRequest) -> TealiumTrackRequest {
        var newTrack = track.data
        if let consentDictionary = consentManager.getUserConsentPreferences()?.toDictionary() {
            newTrack.merge(consentDictionary) { _, new -> Any in
                new
            }
        }

        return TealiumTrackRequest(data: newTrack, completion: track.completion)
    }

    func queue(_ track: TealiumTrackRequest) {
        var newData = track.data
        newData[TealiumKey.queueReason] = TealiumConsentConstants.moduleName
        let newTrack = TealiumTrackRequest(data: newData,
                completion: track.completion)
        let req = TealiumEnqueueRequest(data: newTrack, completion: nil)
        self.delegate?.tealiumModuleRequests(module: self, process: req)
    }

    func releaseQueue() {
        // queue will be released, but will only be allowed to continue if tracking is allowed when track call is resubmitted
        let req = TealiumReleaseQueuesRequest(typeId: "consent", moduleResponses: [TealiumModuleResponse]()) { _, _, _ in
            let report = TealiumReportRequest(message: "Consent Manager: Attempting to send queued track call.")
            self.delegate?.tealiumModuleRequests(module: self,
                    process: report)
        }
        self.delegate?.tealiumModuleRequests(module: self, process: req)
    }

    func purgeQueue() {
        let req = TealiumClearQueuesRequest(typeId: "consent", moduleResponses: [TealiumModuleResponse]()) { _, _, _ in
            let report = TealiumReportRequest(message: "Consent Manager: Purging queue.")
            self.delegate?.tealiumModuleRequests(module: self,
                    process: report)
        }
        self.delegate?.tealiumModuleRequests(module: self, process: req)
    }
}

extension TealiumConsentManagerModule: TealiumConsentManagerDelegate {

    func willDropTrackingCall(_ request: TealiumTrackRequest) {

    }

    func willQueueTrackingCall(_ request: TealiumTrackRequest) {

    }

    func willSendTrackingCall(_ request: TealiumTrackRequest) {

    }

    func consentStatusChanged(_ status: TealiumConsentStatus) {
        switch status {
        case .notConsented:
            self.purgeQueue()
        case .consented:
            self.releaseQueue()
        default:
            return
        }
    }

    func userConsentedToTracking() {

    }

    func userOptedOutOfTracking() {

    }

    func userChangedConsentCategories(categories: [TealiumConsentCategories]) {

    }
}

// public interface for consent manager
public extension Tealium {

    func consentManager() -> TealiumConsentManager? {
        guard let module = modulesManager.getModule(forName: TealiumConsentConstants.moduleName) as? TealiumConsentManagerModule else {
            return nil
        }

        return module.consentManager
    }
}
