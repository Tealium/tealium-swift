//
//  TealiumPublishSettingsRetriever.swift
//  TealiumCore
//
//  Created by Craig Rouse on 02/12/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

extension Date {
    var httpIfModifiedHeader: String {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, dd MMM YYYY HH:mm:ss"
            return "\(dateFormatter.string(from: self)) GMT"
        }
    }
    func addMinutes(_ mins: Double?) -> Date? {
        guard let mins = mins else {
            return nil
        }
        let seconds = mins * 60
        guard let timeInterval = TimeInterval(exactly: seconds) else {
            return nil
        }
        return addingTimeInterval(timeInterval)
    }
}

public enum HttpStatusCodes: Int {
    case notModified = 304
    case ok = 200
}

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
        get {
            if let urlString = config.publishSettingsURL,
                let url = URL(string: urlString) {
                return url
            } else if let profile = config.publishSettingsProfile {
                return URL(string: "\(TealiumValue.tiqBaseURL)\(config.account)/\(profile)/\(config.environment)/\(TealiumValue.tiqURLSuffix)")
            }
            return URL(string: "\(TealiumValue.tiqBaseURL)\(config.account)/\(config.profile)/\(config.environment)/\(TealiumValue.tiqURLSuffix)")
        }
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
                self.diskStorage.save(settings, completion: nil)
            }
        }

    }
    
    func getRemoteSettings(url: URL,
                           lastFetch: Date?,
                           completion: @escaping (RemotePublishSettings?)-> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let lastFetch = lastFetch {
            request.setValue(lastFetch.httpIfModifiedHeader, forHTTPHeaderField: "If-Modified-Since")
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }
        
        urlSession?.tealiumDataTask(with: request) { data, response, error in
            
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
            let startScript = dataString.range(of: "var mps = "),
            let endScript = dataString.range(of: "</script>") else {
            return nil
        }
        
        let string = dataString[..<endScript.lowerBound]
        let newSubString = string[startScript.upperBound...]

        guard let data = newSubString.data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(RemotePublishSettings.self, from: data)

    }
}
