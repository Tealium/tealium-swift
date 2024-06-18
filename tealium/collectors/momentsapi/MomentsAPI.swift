//
//  MomentsAPI.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
#if momentsapi
import TealiumCore
#endif
protocol MomentsAPI {
    func fetchEngineResponse(engineID: String, completion: @escaping (Result<EngineResponse, Error>) -> Void)
    var visitorId: String? { get set }
}

class TealiumMomentsAPI: MomentsAPI {
    private let session: URLSessionProtocol
    private let region: MomentsAPIRegion
    private let account: String
    private let profile: String
    private let referer: String
    var visitorId: String?

    init(region: MomentsAPIRegion,
         account: String,
         profile: String,
         environment: String,
         referer: String? = nil,
         session: URLSessionProtocol = URLSession(configuration: .ephemeral)) {
        self.region = region
        self.account = account
        self.profile = profile
        self.referer = referer ?? "https://tags.tiqcdn.com/utag/\(account)/\(profile)/\(environment)/mobile.html"
        self.session = session
    }

    func fetchEngineResponse(engineID: String, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
        guard let visitorId = self.visitorId else {
            completion(.failure(MomentsError.missingVisitorID))
            return
        }
        performRequestForEngineResponse(engineID: engineID, visitorId: visitorId, completion: completion)
    }
}

// MARK: - Private Methods
private extension TealiumMomentsAPI {
    func performRequestForEngineResponse(engineID: String, visitorId: String, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
        guard let url = constructURL(forEngineID: engineID, visitorID: visitorId) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(referer, forHTTPHeaderField: "Referer")

        session.tealiumDataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    func constructURL(forEngineID engineID: String, visitorID: String) -> URL? {
        // swiftlint:disable line_length
        return URL(string: "https://personalization-api.\(region.rawValue).prod.tealiumapis.com/personalization/accounts/\(account)/profiles/\(profile)/engines/\(engineID)/visitors/\(visitorID)?ignoreTapid=true")
        // swiftlint:enable line_length
    }

    func handleResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
        // URLError would usually indicate a connection error
        if let urlError = error as? URLError {
            completion(.failure(urlError))
            return
        }

        // Check for known HTTP response errors
        if let httpResponse = response as? HTTPURLResponse, let customError = mapStatus(forStatusCode: httpResponse.statusCode) {
            completion(.failure(customError))
            return
        }

        guard let data = data else {
            completion(.failure(URLError(.cannotDecodeRawData)))
            return
        }

        do {
            let moments = try JSONDecoder().decode(EngineResponse.self, from: data)
            completion(.success(moments))
        } catch {
            completion(.failure(error))
        }
    }

    func mapStatus(forStatusCode statusCode: Int) -> MomentsAPIHTTPError? {
        guard let status = MomentsAPIHTTPError(rawValue: statusCode), status != .success else {
            return nil
        }
        return status
    }
}
