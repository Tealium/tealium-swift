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

class TealiumPublishSettingsRetriever: TealiumPublishSettingsRetrieverProtocol {

    var diskStorage: TealiumDiskStorageProtocol
    var urlSession: URLSessionProtocol?
    weak var delegate: TealiumPublishSettingsDelegate?
    var cachedSettings: RemotePublishSettings?
    var config: TealiumConfig
    var lastFetch: Date?
    var fetching = false
    var publishSettingsURL: URL? {
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
         urlSession: URLSessionProtocol? = URLSession(configuration: .ephemeral),
         delegate: TealiumPublishSettingsDelegate) {
        self.config = config
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "publishsettings", isCritical: true)
        self.cachedSettings = getCachedSettings()
        self.urlSession = urlSession
        self.delegate = delegate
        getAndSave()
    }

    func refresh() {
        guard !fetching else {
            return
        }
        guard let cachedSettings = cachedSettings else {
            getAndSave()
            return
        }
        guard let date = lastFetch?.addMinutes(cachedSettings.minutesBetweenRefresh), Date() > date else {
            return
        }
        getAndSave()
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
        guard let dataString = String(data: data, encoding: .utf8),
              let startScript = dataString.range(of: "var mps = ") else {
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

    deinit {
        urlSession?.finishTealiumTasksAndInvalidate()
    }
}

extension HTTPURLResponse {
    private static let etagKey = "Etag"
    var etag: String? {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.1, *) {
            return value(forHTTPHeaderField: Self.etagKey)
        } else {
            return headerString(field: Self.etagKey)
        }
    }

    func headerString(field: String) -> String? {
        return (self.allHeaderFields as NSDictionary)[field] as? String
    }
}
