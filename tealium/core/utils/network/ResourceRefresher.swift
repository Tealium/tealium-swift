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

/**
 * An object that refreshes a single resource at regular intervals.
 *
 * Refresh is requested from the outside, but it's ignored unless the required intervals have passed.
 * The resource is cached locally and it's re-read only on initialization.
 *
 * You can pass a delegate to be informed on current and future loaded resources, as well as errors.
 */
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
    /// An in memory state to remember if the file is cached, to avoiding reading from disk every time
    lazy private(set) var isFileCached: Bool = readResource() != nil
    private var lastEtag: String?
    let errorCooldown: ErrorCooldown?
    public init(resourceRetriever: ResourceRetriever<Resource>,
                diskStorage: TealiumDiskStorageProtocol,
                refreshParameters: RefreshParameters<Resource>,
                errorCooldown: ErrorCooldown? = nil) {
        self.resourceRetriever = resourceRetriever
        self.diskStorage = diskStorage
        self.parameters = refreshParameters
        self.errorCooldown = errorCooldown ?? ErrorCooldown(baseInterval: refreshParameters.errorCooldownBaseInterval,
                                                            maxInterval: refreshParameters.refreshInterval)
    }

    var shouldRefresh: Bool {
        guard !fetching else {
            return false
        }
        guard let lastFetch = lastFetch else {
            return true
        }
        guard errorCooldown == nil || isFileCached else {
            return errorCooldown?.isInCooldown(lastFetch: lastFetch) == false
        }
        guard let newFetchMinimumDate = lastFetch.addSeconds(parameters.refreshInterval) else {
            return true
        }
        return newFetchMinimumDate < Date()
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
                self.updateErrorCooldown(for: nil)
                self.errorCooldown?.newCooldownEvent(error: nil)
            case .failure(let error):
                self.delegate?.resourceRefresher(self, didFailToLoadResource: error)
                self.updateErrorCooldown(for: error)
            }
            self.lastFetch = Date()
            self.fetching = false
        }
    }

    private func updateErrorCooldown(for error: TealiumResourceRetrieverError?) {
        var error = error
        if case let .non200Response(code) = error, code == 304 {
            error = nil
        }
        errorCooldown?.newCooldownEvent(error: error)
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

    private func onResourceLoaded(_ resource: Resource) {
        isFileCached = true
        lastEtag = resource.etag
        delegate?.resourceRefresher(self, didLoad: resource)
    }

    public func setRefreshInterval(_ seconds: Double) {
        parameters.refreshInterval = seconds
        errorCooldown?.maxInterval = seconds
    }
}
