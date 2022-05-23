//
//  ConsentManager.swift
//  ConsentManagerDemo
//
//  Created by Enrico Zannini on 09/12/21.
//  Copyright © 2021 Enrico Zannini. All rights reserved.
//

import Foundation
import TealiumSwift
import Usercentrics

class UserCentricDispatchValidator: DispatchValidator {
    let settingsId: String
    let templateId: String
    var userCentricsReady = false
    var consentCollected: Bool {
        userCentricsReady && !UsercentricsCore.shared.shouldCollectConsent()
    }
    
    init(settingsId: String, templateId: String) {
        self.templateId = templateId
        let options = UsercentricsOptions(settingsId: settingsId)
        UsercentricsCore.configure(options: options)
        self.settingsId = settingsId
        UsercentricsCore.isReady { [weak self] status in
            self?.userCentricsReady = true
        } onFailure: { error in }
        UsercentricsEvent.shared.onConsentUpdated { event in
            // If this class was in another library instead of the sample, how do we find the tealium instance?
            TealiumHelper.shared.tealium?.flushQueue()
        }
    }
    
    var id: String = "UserCentrics"
    
    func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
        guard consentCollected,
              let consent = getConsent() else {
            return (true, [:])
        }
        
        return (false, ["usercentrics_templateid_"+consent.templateId: consent.status])
    }
    
    
    func shouldDrop(request: TealiumRequest) -> Bool {
        guard consentCollected, let consent = getConsent() else { return false }
        return !consent.status
    }
    
    func shouldPurge(request: TealiumRequest) -> Bool {
        shouldDrop(request: request)
    }
    
    private func getConsent() -> UsercentricsServiceConsent? {
        UsercentricsCore.shared.getConsents().first(where: { $0.templateId == self.templateId })
    }
    
}
