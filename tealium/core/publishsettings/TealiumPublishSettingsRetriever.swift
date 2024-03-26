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
        let refreshParameters = RefreshParameters<RemotePublishSettings>(id: "settings", url: url, fileName: nil)
        self.resourceRefresher = ResourceRefresher(resourceRetriever: resourceRetriever, diskStorage: diskStorage, refreshParameters: refreshParameters)
        resourceRefresher?.delegate = self
        if cachedSettings == nil,
           let defaultSettings = loadSettingsFromBundle() {
            cachedSettings = defaultSettings
        }
        refresh()
    }

    func refresh() {
        resourceRefresher?.requestRefresh()
    }

    static func getPublishSettings(from data: Data, etag: String?) -> RemotePublishSettings? {
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

    func loadSettingsFromBundle() -> RemotePublishSettings? {
        try? JSONLoader.fromFile(TealiumValue.settingsResourceName, bundle: .main)
    }

    func resourceRefresher(_ id: String, didLoad resource: RemotePublishSettings) {
        cachedSettings = resource
        delegate?.didUpdate(resource)
    }

    func resourceRefresher(_ id: String, shouldRefresh lastFetch: Date) -> Bool {
        guard let settings = cachedSettings,
            let date = lastFetch.addMinutes(settings.minutesBetweenRefresh) else {
            return true
        }
        return Date() > date
    }
}
