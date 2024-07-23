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
  /// The age verification signal telling whether the user's age is over 18 or pending.
  /// - note: This will publish updates when its value changes.
  @Published var ageVerificationSignal: String
  /// Indicates whether the view to display the user's age is over 18 should be shown.
  /// - note: This will publish updates when its value changes.
  @Published var isShowingAgeVerificationSignal = false
  /// Indicates whether an alert should be displayed to inform the user that they are not verified as over 18.
  /// - note: This will publish updates when its value changes.
  @Published var isShowingAgeVerificationAlert = false

  private lazy var loader: VerificationLoader = {
    return VerificationLoader(verifiedViewAgeModel: self)
  }()

  /// An enumeration representing possible states of an age verification signal.
  enum AgeVerificationSignal: String {
    /// The user's age has been verified to be over 18.
    case ageOver18Standard = "AGE_OVER_18_STANDARD"
    /// The user's age verification is pending.
    case agePending = "AGE_PENDING"
    /// Indicates there was no age verification signal found.
    case noAgeVerificationSignal = "Signal Unavailable"
  }

  /// Creates an instance of this view model.
  init() {
    self.verificationState = .unverified
    self.ageVerificationSignal = AgeVerificationSignal.noAgeVerificationSignal.rawValue
  }

  /// Verifies the user's age is over 18.
  func verifyUserAgeOver18() {
    loader.verifyUserAgeOver18()
  }

  /// Fetches the age verification signal representing whether the user's age is over 18 or pending.
  func fetchAgeVerificationSignal(verifyResult: GIDVerifiedAccountDetailResult) {
    loader.fetchAgeVerificationSignal(verifyResult: verifyResult) {
      self.ageVerificationSignal =
        self.loader.verification?.signal ?? AgeVerificationSignal.noAgeVerificationSignal.rawValue

      let signal = AgeVerificationSignal(rawValue: self.ageVerificationSignal)
      if (signal == .ageOver18Standard) {
        self.isShowingAgeVerificationSignal = true
        self.isShowingAgeVerificationAlert = false
      } else {
        self.isShowingAgeVerificationSignal = false
        self.isShowingAgeVerificationAlert = true
      }
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
