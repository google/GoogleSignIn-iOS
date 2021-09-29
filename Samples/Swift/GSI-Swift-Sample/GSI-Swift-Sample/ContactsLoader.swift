/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Combine
import GoogleSignIn

class ContactsLoader: ObservableObject {
  static let contactsReadonlyScope = "https://www.googleapis.com/auth/contacts.readonly"
  private let baseUrlString = "https://people.googleapis.com/v1/people/me/connections"

  private var components: URLComponents! {
    var comps = URLComponents(string: baseUrlString)
    let personFieldsQuery = URLQueryItem(name: "personFields", value: "names,emailAddresses")
    var queryItems = [personFieldsQuery]

    switch nextPageToken {
    case .firstLoad:
      comps?.queryItems = queryItems
    case .nextPageToken(let token):
      let nextPageQuery = URLQueryItem(name: "pageToken", value: token)
      queryItems.append(nextPageQuery)
      comps?.queryItems = queryItems
    case .noNextPage:
      return nil
    }

    return comps
  }

  private var contactsRequest: URLRequest! {
    let request = URLRequest(url: components.url!)
    return request
  }

  private var session: URLSession! {
    guard let accessToken = GIDSignIn.sharedInstance.currentUser?.authentication.accessToken else { return nil }
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = [
      "Authorization": "Bearer \(accessToken)"
    ]
    return URLSession(configuration: configuration)
  }

  var didChange = PassthroughSubject<[Contact], Never>()
  var allContacts = [Contact]()

  private(set) var nextPageToken: NextPageToken = .firstLoad
  var hasAllContacts: Bool {
    switch nextPageToken {
    case .firstLoad, .nextPageToken:
      return false
    case .noNextPage:
      return true
    }
  }
  private(set) var cancellablePublisher: AnyPublisher<[Contact], Swift.Error>?

  private func request(with nextPageToken: NextPageToken) -> Result<URLRequest, Error> {
    guard var comps = URLComponents(string: baseUrlString) else {
      return .failure(.couldNotCreateURLComponentsWithURLString(baseUrlString))
    }
    let personFieldsQuery = URLQueryItem(name: "personFields", value: "names,emailAddresses")
    var queryItems = [personFieldsQuery]

    switch nextPageToken {
    case .firstLoad:
      comps.queryItems = queryItems
    case .nextPageToken(let token):
      let nextPageQuery = URLQueryItem(name: "pageToken", value: token)
      queryItems.append(nextPageQuery)
      comps.queryItems = queryItems
    case .noNextPage:
      // This case should not match, but Swift requires the switch to be exhaustive
      return .failure(.couldNotCreateURLRequestNoNextPage)
    }

    guard let url = comps.url else {
      return .failure(.couldNotCreateURLWithURLComponents(comps))
    }

    return .success(URLRequest(url: url))
  }

  func loadContacts(
    nextPageToken: NextPageToken,
    completion: @escaping (Result<([Contact], NextPageToken), Error>
    ) -> Void) {
    let request = request(with: nextPageToken)
    switch request {
    case .success(let req):
      let task = session.dataTask(with: req) { data, response, error in
        guard let data = data else { return completion(.failure(.noData)) }
        let decoder = JSONDecoder()
        do {
          let contactsResponse = try decoder.decode(ContactResponse.self, from: data)
          let nextPageToken: NextPageToken = (contactsResponse.nextPageToken != nil)
            ? .nextPageToken(contactsResponse.nextPageToken!)
            : .noNextPage
          let fetchedContacts = contactsResponse.connections
          completion(.success((fetchedContacts, nextPageToken)))
        } catch {
          completion(.failure(.failedToDecodeData(error)))
        }
      }
      task.resume()
    case .failure(let error):
      completion(.failure(error))
    }
  }
}

// MARK: - Error

extension ContactsLoader {
  enum Error: Swift.Error {
    case noData
    case failedToDecodeData(Swift.Error)
    case couldNotCreateURLComponentsWithURLString(String)
    case couldNotCreateURLRequestNoNextPage
    case couldNotCreateURLWithURLComponents(URLComponents)
  }
}

// MARK: - Next Page Token

extension ContactsLoader {
  enum NextPageToken {
    typealias Token = String

    case firstLoad
    case nextPageToken(Token)
    case noNextPage
  }
}
