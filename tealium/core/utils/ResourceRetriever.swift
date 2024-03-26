//
//  ResourceRetriever.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 25/03/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

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

public enum TealiumResourceRetrieverError: TealiumErrorEnum, Equatable {
    case emptyBody
    case couldNotDecodeJSON
    case noResponse
    case notModified
    case non200response(statusCode: Int)
}

public class ResourceRetriever<Resource: Codable> {
    let urlSession: URLSessionProtocol
    public typealias ResourceBuilder = (_ data: Data, _ etag: String?) -> Resource?
    let resourceBuilder: ResourceBuilder
    let logError: ((Error) -> Void)?
    public init(urlSession: URLSessionProtocol, resourceBuilder: @escaping ResourceBuilder, logError: ((Error) -> Void)? = nil) {
        self.urlSession = urlSession
        self.resourceBuilder = resourceBuilder
        self.logError = logError
    }

    public func getResource(url: URL,
                            etag: String?,
                            completion: @escaping (Resource?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *) {
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            } else {
                request.cachePolicy = .reloadIgnoringLocalCacheData
            }
        }
        sendRequest(request) { result in
            if case .failure(let error) = result {
                self.logError?(error)
            }
            completion(try? result.get())
        }
    }

    private func sendRequest(_ request: URLRequest, completion: @escaping (Result<Resource, Error>) -> Void) {
        urlSession.tealiumDataTask(with: request) { data, response, error in
            TealiumQueues.backgroundSerialQueue.async {
                guard let response = response as? HTTPURLResponse, error == nil else {
                    completion(.failure(error ?? TealiumResourceRetrieverError.noResponse))
                    return
                }
                switch response.statusCode {
                case 200..<300:
                    guard let data = data else {
                        completion(.failure(TealiumResourceRetrieverError.emptyBody))
                        return
                    }
                    guard let resource = self.resourceBuilder(data, response.etag) else {
                        completion(.failure(TealiumResourceRetrieverError.couldNotDecodeJSON))
                        return
                    }
                    completion(.success(resource))
                case 304:
                    completion(.failure(TealiumResourceRetrieverError.notModified))
                    return
                default:
                    completion(.failure(TealiumResourceRetrieverError.non200response(statusCode: response.statusCode)))
                    return
                }
            }
        }.resume()
    }
}

public protocol EtagResource {
    var etag: String? { get }
}

public struct RefreshParameters<Resource> {
    let id: String
    let url: URL
    let fileName: String?
    public init(id: String, url: URL, fileName: String?) {
        self.id = id
        self.url = url
        self.fileName = fileName
    }
}

public protocol ResourceRefresherDelegate<Resource>: AnyObject {
    associatedtype Resource
    func resourceRefresher(_ id: String, didLoad resource: Resource)
    func resourceRefresher(_ id: String, shouldRefresh lastFetch: Date) -> Bool
}

public class ResourceRefresher<Resource: Codable & EtagResource> {
    let resourceRetriever: ResourceRetriever<Resource>
    let diskStorage: TealiumDiskStorageProtocol
    let parameters: RefreshParameters<Resource>
    public weak var delegate: (any ResourceRefresherDelegate<Resource>)? {
        didSet {
            if let _ = delegate {
                if let resource = readResource() {
                    lastEtag = resource.etag
                    onResourceLoaded(resource)
                }
            }
        }
    }
    private var fetching = false
    private var lastFetch: Date?
    private var lastEtag: String?
    public init(resourceRetriever: ResourceRetriever<Resource>,
                diskStorage: TealiumDiskStorageProtocol,
                refreshParameters: RefreshParameters<Resource>) {
        self.resourceRetriever = resourceRetriever
        self.diskStorage = diskStorage
        self.parameters = refreshParameters
    }

    private var shouldRefresh: Bool {
        guard !fetching else {
            return false
        }
        guard let lastFetch = lastFetch else {
            return true
        }
        return delegate?.resourceRefresher(parameters.id, shouldRefresh: lastFetch) ?? true
    }

    public func requestRefresh() {
        guard shouldRefresh else {
            return
        }
        refresh()
    }

    private func refresh() {
        fetching = true
        resourceRetriever.getResource(url: parameters.url, etag: lastEtag) { resource in
            if let resource = resource {
                self.onResourceLoaded(resource)
                self.saveResource(resource)
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

    private func onResourceLoaded(_ resource: Resource) {
        lastEtag = resource.etag
        delegate?.resourceRefresher(parameters.id, didLoad: resource)
    }
}
