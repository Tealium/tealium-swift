//
//  ResourceRefresher.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 05/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol ResourceRefresherDelegate<Resource>: AnyObject {
    associatedtype Resource: Codable & EtagResource
    func resourceRefresher(_ refresher: ResourceRefresher<Resource>, didLoad resource: Resource)
    func resourceRefresher(_ refresher: ResourceRefresher<Resource>, didFailToLoadResource error: TealiumResourceRetrieverError)
}

public extension ResourceRefresherDelegate {
    func resourceRefresher(_ refresher: ResourceRefresher<Resource>, didFailToLoadResource error: TealiumResourceRetrieverError) { }
}

public class ResourceRefresher<Resource: Codable & EtagResource> {
    let resourceRetriever: ResourceRetriever<Resource>
    let diskStorage: TealiumDiskStorageProtocol
    private var parameters: RefreshParameters<Resource>
    public var id: String {
        parameters.id
    }
    public weak var delegate: (any ResourceRefresherDelegate<Resource>)? {
        didSet {
            if let _ = delegate {
                if let resource = readResource() {
                    onResourceLoaded(resource)
                }
            }
        }
    }
    private var fetching = false
    private var lastFetch: Date?
    private var isFileCached: Bool?
    private var lastEtag: String?
    private var lastCallError: Error?
    private var consecutiveErrorsCount = 0
    public init(resourceRetriever: ResourceRetriever<Resource>,
                diskStorage: TealiumDiskStorageProtocol,
                refreshParameters: RefreshParameters<Resource>) {
        self.resourceRetriever = resourceRetriever
        self.diskStorage = diskStorage
        self.parameters = refreshParameters
    }

    var shouldRefresh: Bool {
        guard !fetching else {
            return false
        }
        guard let lastFetch = lastFetch else {
            return true
        }
        guard isFileCached ?? checkIfFileIsCached() else {
            return !isInCooldown(lastFetch: lastFetch)
        }
        guard let newFetchMinimumDate = lastFetch.addSeconds(parameters.refreshInterval) else {
            return true
        }
        return newFetchMinimumDate < Date()
    }

    var cooldownInterval: Double? {
        guard let cooldownBaseInterval = parameters.errorCooldownBaseInterval else {
            return nil
        }
        return min(parameters.refreshInterval, cooldownBaseInterval * Double(consecutiveErrorsCount))
    }

    func isInCooldown(lastFetch: Date) -> Bool {
        guard lastCallError != nil else {
            return false
        }
        guard let cooldownInterval = cooldownInterval,
              let cooldownEndDate = lastFetch.addSeconds(cooldownInterval) else {
            return false
        }
        return cooldownEndDate > Date()
    }

    public func requestRefresh() {
        guard shouldRefresh else {
            return
        }
        refresh()
    }

    private func refresh() {
        fetching = true
        resourceRetriever.getResource(url: parameters.url, etag: lastEtag) { result in
            switch result {
            case .success(let resource):
                self.saveResource(resource)
                self.onResourceLoaded(resource)
                self.lastCallError = nil
                self.consecutiveErrorsCount = 0
            case .failure(let error):
                self.delegate?.resourceRefresher(self, didFailToLoadResource: error)
                self.lastCallError = error
                self.consecutiveErrorsCount += 1
            }
            self.lastFetch = Date()
            self.fetching = false
        }
    }

    public func readResource() -> Resource? {
        if let fileName = parameters.fileName {
            return diskStorage.retrieve(fileName, as: Resource.self)
        } else {
            return diskStorage.retrieve(as: Resource.self)
        }
    }

    func saveResource(_ resource: Resource) {
        if let fileName = parameters.fileName {
            self.diskStorage.save(resource, fileName: fileName, completion: nil)
        } else {
            self.diskStorage.save(resource, completion: nil)
        }
    }

    private func checkIfFileIsCached() -> Bool {
        let isCached = readResource() != nil
        isFileCached = isCached
        return isCached
    }

    private func onResourceLoaded(_ resource: Resource) {
        isFileCached = true
        lastEtag = resource.etag
        delegate?.resourceRefresher(self, didLoad: resource)
    }

    public func setRefreshInterval(_ seconds: Double) {
        parameters.refreshInterval = seconds
    }
}
