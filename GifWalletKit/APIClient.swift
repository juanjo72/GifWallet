//
//  Created by Pierluigi Cifani on 02/03/2018.
//  Copyright © 2018 Code Crafters. All rights reserved.
//
import Foundation

public class APIClient {

    let environment: Environment
    let urlSession: URLSession
    var delegateQueue = DispatchQueue.main

    public init(environment: Environment) {
        self.environment = environment
        self.urlSession = URLSession(configuration: .default)
    }

    public func performRequest(forEndpoint endpoint: Endpoint, handler: @escaping (Data?, Swift.Error?) -> Void) {
        let urlRequest: URLRequest
        do {
            urlRequest = try self.createURLRequest(endpoint: endpoint)
        } catch let error {
            delegateQueue.async { handler(nil, error) }
            return
        }

        let task = self.urlSession.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else {
                self.delegateQueue.async { handler(nil, error) }
                return
            }

            guard let data = data else {
                self.delegateQueue.async { handler(nil, Error.malformedResponse) }
                return
            }

            self.delegateQueue.async { handler(data, nil) }
        }
        task.resume()
    }

    private func createURLRequest(endpoint: Endpoint) throws -> URLRequest {
        guard let URL = URL(string: endpoint.path, relativeTo: self.environment.baseURL) else {
            throw Error.malformedURL
        }

        var urlRequest = URLRequest(url: URL)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.allHTTPHeaderFields = endpoint.httpHeaderFields
        urlRequest.setValue("User-Agent", forHTTPHeaderField: "GifWallet - iOS")
        if let parameters = endpoint.parameters {
            do {
                let requestData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                urlRequest.httpBody = requestData
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw Error.malformedParameters
            }
        }
        return urlRequest
    }

    enum Error: Swift.Error {
        case malformedURL
        case malformedParameters
        case malformedResponse
    }
}
