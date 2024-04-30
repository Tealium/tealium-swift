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
        request.setValue("\(referer)", forHTTPHeaderField: "Referer")

        session.tealiumDataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    func constructURL(forEngineID engineID: String, visitorID: String) -> URL? {
        let urlString = "https://personalization-api.\(region.rawValue).prod.tealiumapis.com/personalization/accounts/\(account)/profiles/\(profile)/engines/\(engineID)/visitors/\(visitorID)?ignoreTapid=true"
        return URL(string: urlString)
    }

    func handleResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
        // Handle networking errors
        if let error = error as? URLError, 
            let customError = mapStatus(forStatusCode: error.code.rawValue) {
            completion(.failure(customError))
            return
        }
        
        // Handle any other unknown error
        if let error = error as? NSError,
            let customError = mapStatus(forStatusCode: error.code) {
            // return the original error to be handled by the caller
            completion(.failure(error))
            return
        }
        
        // Handle errors based on response status code
        if let response = response as? HTTPURLResponse, let error = mapStatus(forStatusCode: response.statusCode) {
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
    }

    func mapStatus(forStatusCode statusCode: Int) -> MomentsAPIHTTPError? {
        let status = MomentsAPIHTTPError(statusCode: statusCode)
        guard status != .success else {
            return nil
        }
        return status
    }
}
