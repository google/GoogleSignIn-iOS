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

import Foundation
import GoogleSignIn

#if os(iOS)

/// An observable class for verifying via Google.
final class VerificationLoader: ObservableObject {
  private var verifiedAgeViewModel: VerifiedAgeViewModel

  /// Creates an instance of this loader.
  /// - parameter verifiedAgeViewModel: The view model to use to set verification status on.
  init(verifiedViewAgeModel: VerifiedAgeViewModel) {
    self.verifiedAgeViewModel = verifiedViewAgeModel
  }

  /// Verifies the user's age based upon the selected account.
  /// - note: Successful calls to this will set the `verifiedAgeViewModel`'s `verificationState` property.
  func verifyAccountDetails() {
    let accountDetails: [GIDVerifiableAccountDetail] = [
      GIDVerifiableAccountDetail(accountDetailType:.ageOver18)
    ]

    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      print("There is no root view controller!")
      return
    }

    let verifyAccountDetail = GIDVerifyAccountDetail()
    verifyAccountDetail.verifyAccountDetails(accountDetails, presenting: rootViewController) {
      verifyResult, error in
      guard let verifyResult = verifyResult else {
        self.verifiedAgeViewModel.verificationState = .unverified
        print("Error! \(String(describing: error))")
        return
      }
      self.verifiedAgeViewModel.verificationState = .verified(verifyResult)
    }
  }
}

#endif
