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
    case unknown
    case emptyBody
    case couldNotDecodeJSON
    case non200Response(code: Int)
}

/**
 * An object used to send GET requests to download a JSON and build a Codable resource.
 *
 * Automatically handles retries with an exponential backoff and adds `if-none-match` header if `etag` is provided.
 */
public class ResourceRetriever<Resource: Codable> {
    let urlSession: URLSessionProtocol
    public typealias ResourceBuilder = (_ data: Data, _ etag: String?) -> Resource?
    let resourceBuilder: ResourceBuilder
    var maxRetries = 5
    var retryDelay: Double = 0.5
    public init(urlSession: URLSessionProtocol, resourceBuilder: @escaping ResourceBuilder) {
        self.urlSession = urlSession
        self.resourceBuilder = resourceBuilder
    }

    public func getResource(url: URL,
                            etag: String?,
                            completion: @escaping (Result<Resource, TealiumResourceRetrieverError>) -> Void) {
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

    private func isRetryableError(_ error: TealiumResourceRetrieverError) -> Bool {
        switch error {
        case .unknown:
            return true
        case let .non200Response(code: code):
            return code == 408 || code == 429 || (500..<600).contains(code)
        default:
            return false
        }
    }

    func delayBlock(count: Int, _ block: @escaping () -> Void) {
        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + retryDelay * Double(count)) {
            block()
        }
    }

    private func sendRetryableRequest(_ request: URLRequest, retryCount: Int = 0, completion: @escaping (Result<Resource, TealiumResourceRetrieverError>) -> Void) {
        sendRequest(request) { [weak self] result in
            guard let self = self else { return }
            if case .failure(let error) = result {
                if self.isRetryableError(error) && retryCount < self.maxRetries {
                    let newCount = retryCount + 1
                    self.delayBlock(count: newCount) { [weak self] in
                        self?.sendRetryableRequest(request, retryCount: newCount, completion: completion)
                    }
                    return
                }
            }
            completion(result)
        }
    }

    private func sendRequest(_ request: URLRequest, completion: @escaping (Result<Resource, TealiumResourceRetrieverError>) -> Void) {
        urlSession.tealiumDataTask(with: request) { data, response, error in
            TealiumQueues.backgroundSerialQueue.async {
                guard let response = response as? HTTPURLResponse, error == nil else {
                    completion(.failure(.unknown))
                    return
                }
                guard (200..<300).contains(response.statusCode) else {
                    completion(.failure(.non200Response(code: response.statusCode)))
                    return
                }
                guard let data = data else {
                    completion(.failure(.emptyBody))
                    return
                }
                guard let resource = self.resourceBuilder(data, response.etag) else {
                    completion(.failure(.couldNotDecodeJSON))
                    return
                }
                completion(.success(resource))
            }
        }.resume()
    }
}
