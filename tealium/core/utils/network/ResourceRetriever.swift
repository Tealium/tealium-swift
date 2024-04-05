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
    var maxRetries = 5
    public init(urlSession: URLSessionProtocol, resourceBuilder: @escaping ResourceBuilder) {
        self.urlSession = urlSession
        self.resourceBuilder = resourceBuilder
    }

    public func getResource(url: URL,
                            etag: String?,
                            completion: @escaping (Result<Resource, Error>) -> Void) {
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
        sendRetryableRequest(request, completion: completion)
    }

    private func isRetryableError(_ error: Error) -> Bool {
        if let resourceRetrieverError = error as? TealiumResourceRetrieverError {
            switch resourceRetrieverError {
            case .emptyBody:
                return true
            case let .non200response(statusCode: code):
                if code == 408 || code == 429 || (500..<600).contains(code) {
                    return true
                }
                return false
            default:
                return false
            }
        }
        return true
    }

    private func sendRetryableRequest(_ request: URLRequest, retryCount: Int = 0, completion: @escaping (Result<Resource, Error>) -> Void) {
        sendRequest(request) { [weak self] result in
            guard let self = self else { return }
            if case .failure(let error) = result {
                if self.isRetryableError(error) && retryCount < self.maxRetries {
                    let newCount = retryCount + 1
                    TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + 0.5 * Double(newCount)) { [weak self] in
                        self?.sendRetryableRequest(request, retryCount: newCount, completion: completion)
                    }
                    return
                }
            }
            completion(result)
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
