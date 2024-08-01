/*
 * Copyright 2024 Google LLC
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

import SwiftUI
import GoogleSignIn

#if os(iOS)

/// A class conforming to `ObservableObject` used to  represent a user's verification status.
final class VerifiedAgeViewModel: ObservableObject {
  /// The user's account verification status.
  /// - note: This will publish updates when its value changes.
  @Published var verificationState: VerificationState

  /// Minimum time to expiration for a restored access token (10 minutes).
  let kMinimumRestoredAccessTokenTimeToExpire: TimeInterval = 600.0

  private lazy var loader: VerificationLoader = {
    return VerificationLoader(verifiedViewAgeModel: self)
  }()

  /// Creates an instance of this view model.
  init() {
    self.verificationState = .unverified
  }

  /// Verifies the user's age is over 18.
  func verifyUserAgeOver18() {
    switch self.verificationState {
    case .verified(let result):
      if let expirationDate = result.accessToken?.expirationDate,
         expirationDate.timeIntervalSinceNow <= kMinimumRestoredAccessTokenTimeToExpire {
        result.refreshTokens { (result, error) in
          self.verificationState = .verified(result)
        }
      }
    case .unverified:
      loader.verifyUserAgeOver18()
    }
  }
}

extension VerifiedAgeViewModel {
  /// An enumeration representing verified status.
  enum VerificationState {
    /// The user's account is verified and is the associated value of this case.
    case verified(GIDVerifiedAccountDetailResult)
    /// The user's account is not verified.
    case unverified
  }
}

#endif
