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

struct AppCheckSecretReader {
  private let APIKeyName = "APP_CHECK_WEB_API_KEY"

  var APIKey: String? {
    return APIKeyFromBundle ?? APIKeyFromEnvironment
  }

  /// Method for retrieving API key from environment variable used during CI tests
  private var APIKeyFromEnvironment: String? {
    guard let APIKey = ProcessInfo.processInfo.environment[APIKeyName], !APIKey.isEmpty else {
      print("Failed to get \(APIKeyName) from environment.")
      return nil
    }
    return APIKey
  }

  /// Method for retrieving API key from the bundle during simulator or debug builds
  private var APIKeyFromBundle: String? {
    guard let APIKey = Bundle.main.infoDictionary?[APIKeyName] as? String,
          !APIKey.isEmpty else {
      print("Failed to get \(APIKeyName) from Bundle.")
      return nil
    }
    return APIKey
  }
}
