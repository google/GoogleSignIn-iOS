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

/// An observable class to load the current user's birthday.
final class BirthdayLoader: ObservableObject {
  /// The scope required to read a user's birthday.
  static let birthdayReadScope = "https://www.googleapis.com/auth/user.birthday.read"
  private let baseUrlString = "https://people.googleapis.com/v1/people/me"
  private let personFieldsQuery = URLQueryItem(name: "personFields", value: "birthdays")
  private let birthdaySubject = PassthroughSubject<Birthday, Error>()

  private lazy var components: URLComponents? = {
    var comps = URLComponents(string: baseUrlString)
    comps?.queryItems = [personFieldsQuery]
    return comps
  }()

  private lazy var request: URLRequest? = {
    guard let components = components, let url = components.url else {
      return nil
    }
    return URLRequest(url: url)
  }()

  private lazy var session: URLSession? = {
    guard let accessToken = GIDSignIn
            .sharedInstance
            .currentUser?
            .accessToken
            .tokenString else { return nil }
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = [
      "Authorization": "Bearer \(accessToken)"
    ]
    return URLSession(configuration: configuration)
  }()

  private func sessionWithFreshToken(completion: @escaping (Result<URLSession, Error>) -> Void) {
    GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded { user, error in
      guard let token = user?.accessToken.tokenString else {
        completion(.failure(.couldNotCreateURLSession(error)))
        return
      }
      let configuration = URLSessionConfiguration.default
      configuration.httpAdditionalHeaders = [
        "Authorization": "Bearer \(token)"
      ]
      let session = URLSession(configuration: configuration)
      completion(.success(session))
    }
  }

  /// Creates a `Publisher` to fetch a user's `Birthday`.
  /// - parameter completion: A closure passing back the `AnyPublisher<Birthday, Error>`
  /// upon success.
  /// - note: The `AnyPublisher` passed back through the `completion` closure is created with a
  /// fresh token. See `sessionWithFreshToken(completion:)` for more details.
  func birthdayPublisher(completion: @escaping (AnyPublisher<Birthday, Error>) -> Void) {
    sessionWithFreshToken { [weak self] result in
      switch result {
      case .success(let authSession):
        guard let request = self?.request else {
          return completion(Fail(error: .couldNotCreateURLRequest).eraseToAnyPublisher())
        }
        let bdayPublisher = authSession.dataTaskPublisher(for: request)
          .tryMap { data, error -> Birthday in
            let decoder = JSONDecoder()
            let birthdayResponse = try decoder.decode(BirthdayResponse.self, from: data)
            return birthdayResponse.firstBirthday
          }
          .mapError { error -> Error in
            guard let loaderError = error as? Error else {
              return Error.couldNotFetchBirthday(underlying: error)
            }
            return loaderError
          }
          .receive(on: DispatchQueue.main)
          .eraseToAnyPublisher()
        completion(bdayPublisher)
      case .failure(let error):
        completion(Fail(error: error).eraseToAnyPublisher())
      }
    }
  }
}

extension BirthdayLoader {
  /// An error representing what went wrong in fetching a user's number of day until their birthday.
  enum Error: Swift.Error {
    case couldNotCreateURLSession(Swift.Error?)
    case couldNotCreateURLRequest
    case userHasNoBirthday
    case couldNotFetchBirthday(underlying: Swift.Error)
  }
}
