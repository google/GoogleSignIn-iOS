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

/// An enumeration helping to interact with the environment variables containing
/// the email and password secrets used for testing the Google sign-in flow.
enum Credential: String {
  private var emailKey: String { return "EMAIL_SECRET" }
  private var passwordKey: String { return "PASSWORD_SECRET" }

  case email
  case password

  var rawValue: String {
    switch self {
    case .email:
      guard let email = ProcessInfo.processInfo.environment[emailKey] else {
        fatalError("Failed to retrieve secret email from UI testing bundle")
      }
      return email
    case .password:
      guard let password = ProcessInfo.processInfo.environment[passwordKey] else {
        fatalError("Failed to retrieve secret password from UI testing bundle")
      }
      return password
    }
  }
}
