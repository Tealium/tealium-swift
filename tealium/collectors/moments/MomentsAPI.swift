//
//  MomentsAPI.swift
//  tealium-swift
//
//  Created by Craig Rouse on 16/04/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

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
         session: URLSessionProtocol = URLSession(configuration: .ephemeral)) {
        self.region = region
        self.account = account
        self.profile = profile
        self.referer = "https://tags.tiqcdn.com/utag/\(account)/\(profile)/\(environment)/mobile.html"
        self.session = session
    }

    func fetchEngineResponse(engineID: String, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
        guard let visitorId = self.visitorId else {
            completion(.failure(MomentsError.missingVisitorID))
            return
        }
        
        fetchEngineResponse(engineID: engineID, identifier: visitorId, completion: completion)
    }
    
    fileprivate func fetchEngineResponse(engineID: String, identifier: String, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
        let urlString = "https://personalization-api.\(region.rawValue).prod.tealiumapis.com/personalization/accounts/\(account)/profiles/\(profile)/engines/\(engineID)/visitors/\(identifier)?ignoreTapid=true"
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("\(referer)", forHTTPHeaderField: "Referer")

        session.tealiumDataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
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
        }.resume()
    }
}

