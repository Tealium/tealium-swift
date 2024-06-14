//
//  TealiumPublishSettingsRetriever.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
import Foundation

protocol TealiumPublishSettingsDelegate: AnyObject {
    func didUpdate(_ publishSettings: RemotePublishSettings)
}

public protocol TealiumPublishSettingsRetrieverProtocol {
    var cachedSettings: RemotePublishSettings? { get }
    func refresh()
}

class TealiumPublishSettingsRetriever: TealiumPublishSettingsRetrieverProtocol, ResourceRefresherDelegate {
    typealias Resource = RemotePublishSettings
    let resourceRefresher: ResourceRefresher<RemotePublishSettings>?
    weak var delegate: TealiumPublishSettingsDelegate?
    var cachedSettings: RemotePublishSettings?

    static func publishSettingsURL(config: TealiumConfig) -> URL? {
        if let urlString = config.publishSettingsURL,
           let url = URL(string: urlString) {
            return url
        } else if let profile = config.publishSettingsProfile {
            return URL(string: "\(TealiumValue.tiqBaseURL)\(config.account)/\(profile)/\(config.environment)/\(TealiumValue.tiqURLSuffix)")
        }
        return URL(string: "\(TealiumValue.tiqBaseURL)\(config.account)/\(config.profile)/\(config.environment)/\(TealiumValue.tiqURLSuffix)")
    }

    init(config: TealiumConfig,
         diskStorage: TealiumDiskStorageProtocol? = nil,
         urlSession: URLSessionProtocol = URLSession(configuration: .ephemeral),
         delegate: TealiumPublishSettingsDelegate) {
        let diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "publishsettings", isCritical: true)
        self.delegate = delegate
        guard let url = Self.publishSettingsURL(config: config) else {
            self.resourceRefresher = nil
            return
        }
        let resourceRetriever = ResourceRetriever(urlSession: urlSession, resourceBuilder: { data, etag in
            Self.getPublishSettings(from: data, etag: etag)
        })
        let refreshInterval = (cachedSettings?.minutesBetweenRefresh ?? config.minutesBetweenRefresh ?? 15.0) * 60
        let refreshParameters = RefreshParameters<RemotePublishSettings>(id: "settings",
                                                                         url: url,
                                                                         fileName: nil,
                                                                         refreshInterval: refreshInterval)
        self.resourceRefresher = ResourceRefresher(resourceRetriever: resourceRetriever, diskStorage: diskStorage, refreshParameters: refreshParameters)
        resourceRefresher?.delegate = self
        refresh()
    }

    func refresh() {
        resourceRefresher?.requestRefresh()
    }

    func getCachedSettings() -> RemotePublishSettings? {
        let settings = diskStorage.retrieve(as: RemotePublishSettings.self)
        return settings
    }

    func getAndSave() {
        fetching = true
        guard let mobileHTML = publishSettingsURL else {
            return
        }

        getRemoteSettings(url: mobileHTML,
                          etag: cachedSettings?.etag) { settings in
            TealiumQueues.backgroundSerialQueue.async {
                self.lastFetch = Date()
                self.fetching = false
                if let settings = settings {
                    self.cachedSettings = settings
                    self.diskStorage.save(settings, completion: nil)
                    self.delegate?.didUpdate(settings)
                }
            }
        }

    }

    func getRemoteSettings(url: URL,
                           etag: String?,
                           completion: @escaping (RemotePublishSettings?) -> Void) {

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }

        urlSession?.tealiumDataTask(with: request) { data, response, _ in

            guard let response = response as? HTTPURLResponse else {
                completion(nil)
                return
            }

            switch HttpStatusCodes(rawValue: response.statusCode) {
            case .ok:
                guard let data = data, let publishSettings = self.getPublishSettings(from: data, etag: response.etag) else {
                    completion(nil)
                    return
                }
                completion(publishSettings)
            default:
                completion(nil)
                return
            }
        }.resume()
    }

    func getPublishSettings(from data: Data, etag: String?) -> RemotePublishSettings? {
        let dataString = String(decoding: data, as: UTF8.self)
        guard let startScript = dataString.range(of: "var mps = ") else {
            return nil
        }

        let mpsJSON = dataString[startScript.upperBound...]
        guard let mpsJSONEnd = mpsJSON.range(of: "</script>") else {
            return nil
        }

        let fullMPSScript = mpsJSON[..<mpsJSONEnd.lowerBound]

        guard let data = fullMPSScript.data(using: .utf8) else {
            return nil
        }

        var settings = try? JSONDecoder().decode(RemotePublishSettings.self, from: data)
        settings?.etag = etag
        return settings
    }

    func resourceRefresher(_ refresher: ResourceRefresher<RemotePublishSettings>, didLoad resource: RemotePublishSettings) {
        cachedSettings = resource
        refresher.setRefreshInterval(resource.minutesBetweenRefresh * 60)
        delegate?.didUpdate(resource)
    }
}
