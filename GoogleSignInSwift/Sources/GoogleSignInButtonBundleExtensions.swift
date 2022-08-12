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
import GoogleSignIn

// MARK: - Bundle Extensions

#if SWIFT_PACKAGE
let GoogleSignInBundleName = "GoogleSignIn_GoogleSignIn"
#else
let GoogleSignInBundleName = "GoogleSignIn"
#endif

@available(iOS 13.0, macOS 10.15, *)
extension Bundle {
  /// Gets the bundle for the SDK framework.
  /// - returns An optional instance of `Bundle`.
  /// - note If the main `Bundle` cannot be found, or if the `Bundle` cannot be
  /// found via a class, then this will return nil.
  static func gidFrameworkBundle() -> Bundle? {
    if let mainPath = Bundle.main.path(
      forResource: GoogleSignInBundleName,
      ofType: "bundle"
    ) {
      return Bundle(path: mainPath)
    }

    let classBundle = Bundle(for: GIDSignIn.self)

    if let classPath = classBundle.path(
      forResource: GoogleSignInBundleName,
      ofType: "bundle"
    ) {
      return Bundle(path: classPath)
    } else {
      return nil
    }
  }

  /// Retrieves the Google icon URL from the bundle.
  /// - parameter name: The `String` name for the resource to look up.
  /// - parameter ext: The `String` extension for the resource to look up.
  /// - returns An optional `URL` if the resource is found, nil otherwise.
  static func urlForGoogleResource(
    name: String,
    withExtension ext: String
  ) -> URL? {
    let bundle = Bundle.gidFrameworkBundle()
    return bundle?.url(forResource: name, withExtension: ext)
  }
}

#endif // !arch(arm) && !arch(i386)
