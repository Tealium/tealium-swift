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
    func fetchMoments(completion: @escaping (Result<[TealiumVisitorProfile], Error>) -> Void)
    var visitorId: String? { get set }
}

class TealiumMomentsAPI: MomentsAPI {    
    private let session: URLSessionProtocol
    private let region: MomentsAPIRegion
    private let account: String
    private let profile: String
    private let engineID: String
    private let referer: String
    var visitorId: String?

    init(region: MomentsAPIRegion,
         account: String,
         profile: String,
         environment: String,
         engineID: String,
//         visitorId: String,
         session: URLSessionProtocol = URLSession(configuration: .ephemeral)) {
        self.region = region
        self.account = account
        self.profile = profile
        self.engineID = engineID
        self.referer = "https://tags.tiqcdn.com/utag/\(account)/\(profile)/\(environment)/mobile.html"
//        self.visitorId = visitorId
        self.session = session
    }

    func fetchMoments(completion: @escaping (Result<[TealiumVisitorProfile], Error>) -> Void) {
        guard let visitorId = self.visitorId else {
//            completion(.failure(Error(account)))
            return
        }
        fetchMoments(identifier: visitorId, completion: completion)
    }
    
    fileprivate func fetchMoments(identifier: String, completion: @escaping (Result<[TealiumVisitorProfile], Error>) -> Void) {
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
                let moments = try JSONDecoder().decode([TealiumVisitorProfile].self, from: data)
                completion(.success(moments))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

/*
 let tealiumMomentsAPI = TealiumMomentsAPI(apiKey: "YourApiKey")
 tealiumMomentsAPI.fetchMoments { result in
     switch result {
     case .success(let moments):
         print("Moments fetched successfully:", moments)
     case .failure(let error):
         print("Error fetching moments:", error)
     }
 }
 
 */
