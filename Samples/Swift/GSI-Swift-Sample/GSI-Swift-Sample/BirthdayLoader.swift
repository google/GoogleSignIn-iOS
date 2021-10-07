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

final class BirthdayLoader: ObservableObject {
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

  func birthday() -> AnyPublisher<Birthday, Error> {
    return session!.dataTaskPublisher(for: request!)
      .tryMap { data, error -> Birthday in
        let decoder = JSONDecoder()
        let birthdayResponse = try decoder.decode(BirthdayResponse.self, from: data)
        guard let birthday = birthdayResponse.birthdays.first else {
          #warning("This should not fataError")
          fatalError("Could not get bday")
        }
        return birthday
      }
      .mapError { error in
        return .couldNotFetchBirthday(error)
      }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
}

extension BirthdayLoader {
  enum Error: Swift.Error {
    case couldNotFetchBirthday(Swift.Error)
  }
}
