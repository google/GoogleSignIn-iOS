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

/// A class to load the current user's birthday.
final class BirthdayLoader {
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
            .authentication
            .accessToken else { return nil }
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = [
      "Authorization": "Bearer \(accessToken)"
    ]
    return URLSession(configuration: configuration)
  }()

  private func sessionWithFreshToken() async throws -> URLSession {
    guard let authentication = GIDSignIn.sharedInstance.currentUser?.authentication else {
      throw Error.noCurrentUserForSessionWithFreshToken
    }

    let freshAuth = try await authentication.doWithFreshTokens()
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = [
      "Authorization": "Bearer \(freshAuth.accessToken)"
    ]
    let session = URLSession(configuration: configuration)
    return session
  }

  /// Creates a `Publisher` to fetch a user's `Birthday`.
  /// - parameter completion: A closure passing back the `AnyPublisher<Birthday, Error>`
  /// upon success.
  /// - note: The `AnyPublisher` passed back through the `completion` closure is created with a
  /// fresh token. See `sessionWithFreshToken(completion:)` for more details.
  func loadBirthday() async throws -> Birthday {
    let session = try await sessionWithFreshToken()
    guard let request = request else {
      throw Error.couldNotCreateURLRequest
    }
    let birthdayData = try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Data, Swift.Error>) -> Void in
      let task = session.dataTask(with: request) { data, response, error in
        guard let data = data else {
          return continuation.resume(throwing: error ?? Error.noBirthdayData)
        }
        continuation.resume(returning: data)
      }
      task.resume()
    }
    let decoder = JSONDecoder()
    let birthdayResponse = try decoder.decode(BirthdayResponse.self, from: birthdayData)
    return birthdayResponse.firstBirthday
  }
}

extension BirthdayLoader {
  /// An error for what went wrong in fetching a user's number of days until their birthday.
  enum Error: Swift.Error {
    case noCurrentUserForSessionWithFreshToken
    case couldNotCreateURLRequest
    case noBirthdayData
  }
}
