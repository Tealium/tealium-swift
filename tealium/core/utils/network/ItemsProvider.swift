//
//  ItemsProvider.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 20/02/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

public struct ItemsFile<Item: Codable & Equatable>: Codable, EtagResource, Equatable {
    public let etag: String?
    public let items: [Item]
}

public protocol ItemsProviderDelegate<Item>: AnyObject {
    associatedtype Item
    func didLoadItems(_ items: [Item])
}

public enum ItemsFileLocation {
    case local(String)
    case remote(String)
    case none
}

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
                urlSession: URLSessionProtocol = URLSession(configuration: .ephemeral),
                diskStorage: TealiumDiskStorageProtocol,
                logger: TealiumLoggerProtocol?) {

        func createRefresher(urlString: String?) -> ResourceRefresher<Resource>? {
            guard let urlString,
                  !urlString.isEmpty,
                  let url = URL(string: urlString) else {
                return nil
            }
            let resourceRetriever = ResourceRetriever<Resource>(urlSession: urlSession) { data, etag in
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
    /// Logs verbose information
    /// - Parameter message: `String` message to log to the console
    private func logError(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium \(id)",
                                           message: message, info: nil,
                                           logLevel: .error, category: .general)
        logger?.log(logRequest)
    }

    /// Logs verbose information about events occurring in the `TealiumLocation` module
    /// - Parameter message: `String` message to log to the console
    private func logInfo(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium \(id)",
                                           message: message, info: nil,
                                           logLevel: .debug, category: .general)
        logger?.log(logRequest)
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
