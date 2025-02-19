//
//  BlocklistProvider.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 19/02/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//
import Foundation
#if autotracking
import TealiumCore
#endif

struct BlocklistFile: Codable, EtagResource {
    let etag: String?
    let blocklist: [String]
}
protocol BlocklistProviderDelegate: AnyObject {
    func didLoadBlocklist(_ blocklist: [String])
}

class BlocklistProvider {
    private var logger: TealiumLoggerProtocol? {
        config.logger
    }
    private let bundle: Bundle
    private let config: TealiumConfig
    private let resourceRefresher: ResourceRefresher<BlocklistFile>?
    private weak var delegate: BlocklistProviderDelegate?
    init(config: TealiumConfig,
         bundle: Bundle,
         urlSession: URLSessionProtocol = URLSession(configuration: .ephemeral),
         diskStorage: TealiumDiskStorageProtocol) {

        func createRefresher(urlString: String?) -> ResourceRefresher<BlocklistFile>? {
            guard let urlString,
                !urlString.isEmpty,
                  let blocklistUrl = URL(string: urlString) else {
                return nil
            }
            let resourceRetriever = ResourceRetriever<BlocklistFile>(urlSession: urlSession) { data, etag in
                guard let blocklist = try? JSONDecoder().decode([String].self, from: data) else {
                    return nil
                }
                return BlocklistFile(etag: etag, blocklist: blocklist)
            }
            let parameters = RefreshParameters<BlocklistFile>(id: "blocklist",
                                                              url: blocklistUrl,
                                                              fileName: nil,
                                                              refreshInterval: Double.infinity,
                                                              errorCooldownBaseInterval: Double.infinity)
            let refresher = ResourceRefresher(resourceRetriever: resourceRetriever,
                                              diskStorage: diskStorage,
                                              refreshParameters: parameters)
            return refresher
        }

        self.config = config
        self.bundle = bundle
        if let url = config.autoTrackingBlocklistURL {
            self.resourceRefresher = createRefresher(urlString: url)
        } else {
            self.resourceRefresher = nil
        }
    }

    func loadBlocklist(delegate: BlocklistProviderDelegate) {
        self.delegate = delegate
        if let file = config.autoTrackingBlocklistFilename {
            self.loadLocalBlocklist(file: file)
        } else {
            self.resourceRefresher?.delegate = self
            self.resourceRefresher?.requestRefresh()
        }
    }

    private func loadLocalBlocklist(file: String) {
        do {
            let blocklist: [String] = try JSONLoader.fromFile(file, bundle: bundle, logger: logger)
            reportLoadedBlocklist(blocklist)
        } catch {
            reportFailedToLoad(error: error)
        }
    }

    /// Logs verbose information about events occurring in the `TealiumAutotracking` module
    /// - Parameter message: `String` message to log to the console
    private func logError(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium Autotracking",
                                           message: message, info: nil,
                                           logLevel: .error, category: .general)
        logger?.log(logRequest)
    }

    /// Logs verbose information about events occurring in the `TealiumAutotracking` module
    /// - Parameter message: `String` message to log to the console
    private func logInfo(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium Autotracking",
                                           message: message, info: nil,
                                           logLevel: .debug, category: .general)
        logger?.log(logRequest)
    }

    private func reportFailedToLoad(error: Error) {
        logError(message: "Failed to load local blocklist with error:\n" + error.localizedDescription)
        delegate?.didLoadBlocklist([])
    }

    private func reportLoadedBlocklist(_ blocklist: [String]) {
        logInfo(message: "\(String(describing: blocklist.count)) blocklist items")
        delegate?.didLoadBlocklist(blocklist)
    }
}

extension BlocklistProvider: ResourceRefresherDelegate {
    typealias Resource = BlocklistFile
    func resourceRefresher(_ refresher: ResourceRefresher<BlocklistFile>, didLoad resource: BlocklistFile) {
        reportLoadedBlocklist(resource.blocklist)
    }

    func resourceRefresher(_ refresher: ResourceRefresher<BlocklistFile>, didFailToLoadResource error: TealiumResourceRetrieverError) {
        if case .non200Response(let code) = error, code != 304 {
            return
        }
        if refresher.readResource() == nil {
            reportFailedToLoad(error: error)
        }
    }
}
