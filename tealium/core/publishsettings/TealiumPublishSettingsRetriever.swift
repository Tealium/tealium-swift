//
//  TealiumPublishSettingsRetriever.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
import Foundation

protocol TealiumPublishSettingsDelegate: class {
    func didUpdate(_ publishSettings: RemotePublishSettings)
}

class TealiumPublishSettingsRetriever {

    var diskStorage: TealiumDiskStorageProtocol
    var urlSession: URLSessionProtocol?
    weak var delegate: TealiumPublishSettingsDelegate?
    var cachedSettings: RemotePublishSettings?
    var config: TealiumConfig
    var hasFetched = false
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
        refresh()
    }

    func refresh() {
        // always request on launch
        if !hasFetched || cachedSettings == nil {
            getAndSave()
            return
        }

        guard let date = cachedSettings?.lastFetch.addMinutes(cachedSettings?.minutesBetweenRefresh), Date() > date else {
            return
        }
        getAndSave()
    }

    func getCachedSettings() -> RemotePublishSettings? {
        let settings = diskStorage.retrieve(as: RemotePublishSettings.self)
        return settings
    }

    func getAndSave() {
        hasFetched = true

        guard let mobileHTML = publishSettingsURL else {
            return
        }

        getRemoteSettings(url: mobileHTML,
                          lastFetch: cachedSettings?.lastFetch) { settings in
            if let settings = settings {
                self.cachedSettings = settings
                self.diskStorage.save(settings, completion: nil)
                self.delegate?.didUpdate(settings)
            } else {
                self.cachedSettings?.lastFetch = Date()
            }
        }

    }

    func getRemoteSettings(url: URL,
                           lastFetch: Date?,
                           completion: @escaping (RemotePublishSettings?) -> Void) {

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let lastFetch = lastFetch {
            request.setValue(lastFetch.httpIfModifiedHeader, forHTTPHeaderField: "If-Modified-Since")
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }

        urlSession?.tealiumDataTask(with: request) { data, response, _ in

            guard let response = response as? HTTPURLResponse else {
                completion(nil)
                return
            }

            switch HttpStatusCodes(rawValue: response.statusCode) {
            case .ok:
                guard let publishSettings = self.getPublishSettings(from: data!) else {
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

    func getPublishSettings(from data: Data) -> RemotePublishSettings? {
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

        return try? JSONDecoder().decode(RemotePublishSettings.self, from: data)
    }
}
