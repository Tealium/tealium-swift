//
//  SessionStarter.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol SessionStarterProtocol {
    var sessionURL: String { get }
    var urlSession: URLSessionProtocol { get }
    func requestSession(_ completion: @escaping (Result<HTTPURLResponse, Error>) -> Void)
}

public struct SessionStarter: SessionStarterProtocol {

    var config: TealiumConfig
    public var urlSession: URLSessionProtocol

    public init(config: TealiumConfig,
                urlSession: URLSessionProtocol = URLSession(configuration: .ephemeral)) {
        self.config = config
        self.urlSession = urlSession
    }

    /// Sets the session URL
    /// - Returns: `String` The session url.
    public var sessionURL: String {
        let timestamp = Date().unixTimeMilliseconds
        return "\(TealiumValue.sessionBaseURL)\(config.account)/\(config.profile)/\(timestamp)&cb=\(timestamp)"
    }

    /// Makes a request to the Tealium CDN session registry.
    /// - Parameter completion: `Result<HTTPURLResponse, Error>` Optional completion handling if needed.
    public func requestSession(_ completion: @escaping (Result<HTTPURLResponse, Error>) -> Void = { _ in }) {
        guard let url = URL(string: sessionURL) else {
            return
        }
        urlSession.tealiumDataTask(with: url) { _, response, error in
            if error != nil {
                completion(.failure(SessionError.errorInRequest))
                return
            }
            guard let response = response as? HTTPURLResponse,
                    (200 ..< 300).contains(response.statusCode) else {
                completion(.failure(SessionError.invalidResponse))
                return
            }
            completion(.success(response))
        }.resume()
    }

}
