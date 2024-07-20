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

struct AgeVerificationResultView: View {
  /// The age verification signal telling whether the user's age is over 18 or pending.
  let ageVerificationSignal: String

  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    NavigationView {
      VStack {
        Text("Age Verification Signal: \(ageVerificationSignal)")
        Spacer()
      }
      .navigationTitle("User is verified over 18!")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
  }
}
