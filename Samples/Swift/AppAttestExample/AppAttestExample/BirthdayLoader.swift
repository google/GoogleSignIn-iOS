/*
 * Copyright 2023 Google LLC
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

import Foundation
import GoogleSignIn

class BirthdayLoader {
  /// The scope required to read a user's birthday.
  static let birthdayReadScope = "https://www.googleapis.com/auth/user.birthday.read"
  private let baseUrlString = "https://people.googleapis.com/v1/people/me"
  private let personFieldsQuery = URLQueryItem(name: "personFields", value: "birthdays")

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

  private func sessionWithFreshToken(completion: @escaping (Result<URLSession, Error>) -> Void) {
    GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded { user, error in
      guard let token = user?.accessToken.tokenString else {
        completion(.failure(.couldNotRefreshToken))
        return
      }
      let config = URLSessionConfiguration.default
      config.httpAdditionalHeaders = [
        "Authorization": "Bearer \(token)"
      ]
      let session = URLSession(configuration: config)
      completion(.success(session))
    }
  }

  func requestBirthday(completion: @escaping (Result<Birthday, Error>) -> Void) {
    guard let req = request else {
      completion(.failure(Error.noRequest))
      return
    }
    sessionWithFreshToken { sessionResult in
      switch sessionResult {
      case .success(let session):
        let task = session.dataTask(with: req) { data, response, error in
          guard let data else {
            completion(.failure(Error.noData))
            return
          }
          do {
            let jsonData = try JSONSerialization.jsonObject(with: data)
            guard let json = jsonData as? [String: Any] else {
              completion(.failure(Error.jsonDataCannotCastToString))
              return
            }
            guard let birthdays = json["birthdays"] as? [[String: Any]],
                  let firstBday = birthdays.first?["date"] as? [String: Int],
                  let day = firstBday["day"],
                  let month = firstBday["month"] else {
              completion(.failure(Error.noBirthday))
              return
            }
            completion(.success(Birthday(day: day, month: month)))
          } catch {
            completion(.failure(Error.noJSON))
          }
        }
        task.resume()
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

extension BirthdayLoader {
  enum Error: Swift.Error {
    case noRequest
    case noData
    case noJSON
    case jsonDataCannotCastToString
    case noBirthday
    case couldNotRefreshToken
  }
}

struct Birthday: CustomStringConvertible {
  let day: Int
  let month: Int

  var description: String {
    return "Day: \(day); month: \(month)"
  }
}
