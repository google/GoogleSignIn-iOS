/*
 * Copyright 2022 Google LLC
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

enum Credential: String {
  static let bundle: Bundle? = Bundle(identifier: "com.google.DaysUntilBirthdayUITests-iOS-")
  private var emailKey: String { return "EMAIL_SECRET" }
  private var passwordKey: String { return "PASSWORD_SECRET" }

  case email
  case password

  var rawValue: String {
    switch self {
    case .email:
      guard let email = Credential
              .bundle?
              .object(forInfoDictionaryKey: emailKey) as? String else {
        fatalError("Failed to retrieve secret email from UI testing bundle")
      }
      return email
    case .password:
      guard let password = Credential
              .bundle?
              .object(forInfoDictionaryKey: passwordKey) as? String else {
        fatalError("Failed to retrieve secret password from UI testing bundle")
      }
      return password
    }
  }
}
