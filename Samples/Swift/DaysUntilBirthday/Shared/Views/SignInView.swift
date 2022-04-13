/*
 * Copyright 2021 Google LLC
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

struct SignInView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel

  var body: some View {
    VStack {
      HStack {
        let buttonViewModel = GoogleSignInButtonViewModel(
          scheme: .light,
          style: .standard
        )
        GoogleSignInButton(
          viewModel: buttonViewModel,
          action: authViewModel.signIn
        )
          .accessibility(hint: Text("Sign in with Google button."))
          .padding()
      }
      Spacer()
    }
  }
}
