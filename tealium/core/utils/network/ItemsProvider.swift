//
//  ItemsProvider.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 20/02/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A representation of a downloaded and cached local File.
public struct ItemsFile<Item: Codable & Equatable>: Codable, EtagResource, Equatable {
    /// It will be used to avoid downloading that file again in case it's not updated.
    public let etag: String?
    /// A list of generic items
    public let items: [Item]
}

/// A delegate that will receive an array of items when they are downloaded,
/// or an empty array if the download failed and there's no items in the cache
public protocol ItemsProviderDelegate<Item>: AnyObject {
    associatedtype Item
    func didLoadItems(_ items: [Item])
}

/// A standardized enum to express location of a file that could be local (into the assets) or remote (at a given url)
public enum ItemsFileLocation {
    case local(String)
    case remote(String)
    case none
}

/**
 * A class that provides an array of items to it's delegate, downloading them and caching them for future launches.
 *
 * It internally uses a ResourceRefresher, but it doesn't refresh items during the same launch.
 * Items are refreshed only on a new launch and the file is only downloaded if the etag changed.
 */
open class ItemsProvider<Item: Codable & Equatable> {
    public typealias Resource = ItemsFile<Item>

    private let id: String
    private let logger: TealiumLoggerProtocol?
    private let bundle: Bundle
    private let location: ItemsFileLocation
    private let resourceRefresher: ResourceRefresher<Resource>?
    weak private var delegate: (any ItemsProviderDelegate<Item>)?

    public init(id: String,
                location: ItemsFileLocation,
                bundle: Bundle,
                urlSession: URLSessionProtocol? = nil,
                diskStorage: TealiumDiskStorageProtocol,
                logger: TealiumLoggerProtocol?) {

        func createRefresher(urlString: String?) -> ResourceRefresher<Resource>? {
            guard let urlString,
                  !urlString.isEmpty,
                  let url = URL(string: urlString) else {
                return nil
            }
            let resourceRetriever = ResourceRetriever<Resource>(urlSession: urlSession ?? URLSession(configuration: .ephemeral)) { data, etag in
                guard let items = try? JSONDecoder().decode([Item].self, from: data) else {
                    return nil
                }
                return ItemsFile(etag: etag, items: items)
            }
            let parameters = RefreshParameters<Resource>(id: id,
                                                         url: url,
                                                         fileName: nil,
                                                         refreshInterval: Double.infinity,
                                                         errorCooldownBaseInterval: Double.infinity)
            let refresher = ResourceRefresher(resourceRetriever: resourceRetriever,
                                              diskStorage: diskStorage,
                                              refreshParameters: parameters)
            return refresher
        }
        self.id = id
        self.location = location
        self.bundle = bundle
        self.logger = logger
        if case let .remote(url) = location {
            resourceRefresher = createRefresher(urlString: url)
        } else {
            resourceRefresher = nil
        }
    }

    /**
     * Loads the items and receives the list in the delegate provided as a parameter.
     *
     * - parameter delegate: The `ItemsProviderDelegate` that will receive the items when they are loaded.
     */
    public func loadItems(delegate: any ItemsProviderDelegate<Item>) {
        self.delegate = delegate
        if let refresher = resourceRefresher {
            refresher.delegate = self
            refresher.requestRefresh()
        } else if case let .local(file) = location {
            loadLocalItems(file: file)
        } else {
            reportLoadedItems(items: [])
        }
    }
    private func loadLocalItems(file: String) {
        do {
            let items: [Item] = try JSONLoader.fromFile(file, bundle: bundle, logger: logger)
            reportLoadedItems(items: items)
        } catch {
            reportFailedToLoad(error: error)
        }
    }
    open func reportFailedToLoad(error: Error) {
        logError(message: "Failed to load \(id) items with error:\n" + error.localizedDescription)
        delegate?.didLoadItems([])
    }

    open func reportLoadedItems(items: [Item]) {
        logInfo(message: "\(String(describing: items.count)) \(id) Created")
        delegate?.didLoadItems(items)
    }
    /// Logs verbose information about an error
    /// - Parameter message: `String` message to log to the console
    private func logError(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium \(id)",
                                           message: message, info: nil,
                                           logLevel: .error, category: .general)
        logger?.log(logRequest)
    }

    /// Logs verbose information about an event
    /// - Parameter message: `String` message to log to the console
    private func logInfo(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium \(id)",
                                           message: message, info: nil,
                                           logLevel: .debug, category: .general)
        logger?.log(logRequest)
    }

    deinit {
        if let session = resourceRefresher?.resourceRetriever.urlSession {
            resourceRefresher?.resourceRetriever.stop()
            session.finishTealiumTasksAndInvalidate()
        }
    }
}

extension ItemsProvider: ResourceRefresherDelegate {
    public func resourceRefresher(_ refresher: ResourceRefresher<Resource>, didLoad resource: Resource) {
        reportLoadedItems(items: resource.items)
    }
    public func resourceRefresher(_ refresher: ResourceRefresher<Resource>, didFailToLoadResource error: TealiumResourceRetrieverError) {
        if case .non200Response(let code) = error, code == 304 {
            return
        }
        if refresher.readResource() == nil {
            reportFailedToLoad(error: error)
        }
    }
}
