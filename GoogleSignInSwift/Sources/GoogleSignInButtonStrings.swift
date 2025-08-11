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

#if !arch(arm) && !arch(i386)

import Foundation

/// A type retrieving the localized strings for the sign-in button text.
@available(iOS 13.0, macOS 10.15, *)
struct GoogleSignInButtonString {
  /// Button text used as both key in localized strings files and default value
  /// for the standard button.
  private let standardButtonText = "Sign in"
  /// Button text used as both key in localized strings files and default value
  /// for the wide button.
  private let wideButtonText = "Sign in with Google"

  /// The table name for localized strings (i.e. file name before .strings
  /// suffix).
  private let stringsTableName = "GoogleSignIn"

  /// Returns the localized string for the key if available, or the supplied
  /// default text if not.
  /// - parameter key: A `String` key to look up.
  /// - parameter text: The default `String` text.
  /// - returns Either the found `String` or the provided default text.
  private func localizedString(key: String, text: String) -> String {
    guard let frameworkBundle = Bundle.gidFrameworkBundle() else { return text }
    return frameworkBundle.localizedString(
      forKey: key,
      value: text,
      table: stringsTableName
    )
  }

  /// Localized text for the standard button.
  @available(iOS 13.0, macOS 10.15, *)
  var localizedStandardButtonText: String {
    return localizedString(key: standardButtonText, text: "No translation")
  }

  /// Localized text for the wide button.
  @available(iOS 13.0, macOS 10.15, *)
  var localizedWideButtonText: String {
    return localizedString(key: wideButtonText, text: "No translation")
  }
}

#endif // !arch(arm) && !arch(i386)
