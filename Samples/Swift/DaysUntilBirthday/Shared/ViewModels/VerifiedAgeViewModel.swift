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

final class VerifiedAgeViewModel: ObservableObject {
  /// The user's account verification status.
  /// - note: This will publish updates when its value changes.
  @Published var verificationState: VerificationState

  private var loader: VerificationLoader {
    return VerificationLoader(verifiedViewAgeModel: self)
  }

  /// Creates an instance of this view model.
  init() {
    self.verificationState = .unverified
  }

  /// Verifies the user.
  func verifyAccountDetails() {
    switch self.verificationState {
    case .unverified:
      loader.verifyAccountDetails()
    case .verified:
      return
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
