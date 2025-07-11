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
  @ObservedObject var vm = GoogleSignInButtonViewModel()

  var body: some View {
    VStack {
      HStack {
        VStack {
          GoogleSignInButton(viewModel: vm, action: authViewModel.signIn)
            .accessibilityIdentifier("GoogleSignInButton")
            .accessibility(hint: Text("Sign in with Google button."))
            .padding()
          VStack {
            HStack {
              Text("Button style:")
                .padding(.leading)
              Picker("", selection: $vm.style) {
                ForEach(GoogleSignInButtonStyle.allCases) { style in
                  Text(style.rawValue.capitalized)
                    .tag(GoogleSignInButtonStyle(rawValue: style.rawValue)!)
                }
              }
              Spacer()
            }
            HStack {
              Text("Button color:")
                .padding(.leading)
              Picker("", selection: $vm.scheme) {
                ForEach(GoogleSignInButtonColorScheme.allCases) { scheme in
                  Text(scheme.rawValue.capitalized)
                    .tag(GoogleSignInButtonColorScheme(rawValue: scheme.rawValue)!)
                }
              }
              Spacer()
            }
            HStack {
              Text("Button state:")
                .padding(.leading)
              Picker("", selection: $vm.state) {
                ForEach(GoogleSignInButtonState.allCases) { state in
                  Text(state.rawValue.capitalized)
                    .tag(GoogleSignInButtonState(rawValue: state.rawValue)!)
                }
              }
              Spacer()
            }
          }
          #if os(iOS)
            .pickerStyle(.segmented)
          #endif
        }
      }
      Spacer()
    }
  }
}
