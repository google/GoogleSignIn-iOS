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

import SwiftUI
import GoogleSignInSwift

struct ContentView: View {
  let vm = GoogleSignInButtonViewModel(scheme: .light, style: .standard)
  @State private var signInAttempts = 0

  var body: some View {
    Text("Sign In Button Taps: \(signInAttempts)")
      .accessibilityIdentifier("SignInButtonTaps")
    GoogleSignInButton(viewModel: vm) {
      signInAttempts += 1
    }
    .accessibilityIdentifier("GoogleSignInButton")
  }
}
