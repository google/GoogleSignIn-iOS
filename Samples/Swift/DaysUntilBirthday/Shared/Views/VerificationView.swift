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

struct VerificationView: View {
  @ObservedObject var verifiedAgeViewModel: VerifiedAgeViewModel

  var body: some View {
    switch verifiedAgeViewModel.verificationState {
    case .verified(let result):
      Button("Fetch Age Verification Signal") {
        verifiedAgeViewModel.fetchAgeVerificationSignal(verifyResult: result)
      }
      .padding(10)
      .overlay(
          RoundedRectangle(cornerRadius: 30)
              .stroke(Color.gray)
      )
      .padding(.bottom)

      VStack(alignment:.leading) {
        Text("List of result object properties:")
          .font(.headline)

        HStack(alignment: .top) {
          Text("Access Token:")
          Text(result.accessTokenString ?? "Not available")
        }
        HStack(alignment: .top) {
          Text("Refresh Token:")
          Text(result.refreshTokenString ?? "Not available")
        }
        HStack {
          Text("Expiration:")
          if let expirationDate = result.expirationDate {
            Text(formatDateWithDateFormatter(expirationDate))
          } else {
            Text("Not available")
          }
        }
        Spacer()
      }
      .navigationTitle("Verified Account!")
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button(NSLocalizedString("Refresh", comment: "Refresh button"), 
                 action:{refresh(results: result)})
        }
      }
      .sheet(isPresented: $verifiedAgeViewModel.isShowingAgeVerificationSignal) {
          AgeVerificationResultView(ageVerificationSignal: verifiedAgeViewModel.ageVerificationSignal)
      }
      .alert(isPresented: $verifiedAgeViewModel.isShowingAgeVerificationAlert, content: {
        Alert(
            title: Text("Oh no! User is not verified over 18."),
            message: Text("Age Verification Signal: \(verifiedAgeViewModel.ageVerificationSignal)"),
            dismissButton: .cancel()
        )
      })
    case .unverified:
      ProgressView()
        .navigationTitle(NSLocalizedString("Unverified account",
                                           comment: "Unverified account label"))
    }
  }

  func formatDateWithDateFormatter(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    return dateFormatter.string(from: date)
  }

  func refresh(results: GIDVerifiedAccountDetailResult) {
    results.refreshTokens { (result, error) in
      verifiedAgeViewModel.verificationState = .verified(result)
    }
  }
}
