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
import GoogleSignIn

#if os(iOS)
/// A wrapper for `GIDSignInButton` so that it can be used in SwiftUI.
struct GoogleSignInButtonWrapper: UIViewRepresentable {
  let handler: () -> Void

  init(handler: @escaping () -> Void) {
    self.handler = handler
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }

  func makeUIView(context: Context) -> GIDSignInButton {
    let signInButton = GIDSignInButton()
    signInButton.addTarget(context.coordinator,
                           action: #selector(Coordinator.callHandler),
                           for: .touchUpInside)
    return signInButton
  }

  func updateUIView(_ uiView: UIViewType, context: Context) {
    context.coordinator.handler = handler
  }
}

extension GoogleSignInButtonWrapper {
  class Coordinator {
    var handler: (() -> Void)?

    @objc func callHandler() {
      handler?()
    }
  }
}

#elseif os(macOS)
struct GoogleSignInButtonMac: View {
  @EnvironmentObject var viewModel: AuthenticationViewModel

  var body: some View {
    Button(action: {
      viewModel.signIn()
    }) {
      Text("SIGN IN")
          .frame(width: 100 , height: 50, alignment: .center)
    }
     .background(Color.blue)
     .foregroundColor(Color.white)
     .cornerRadius(5)
     .accessibilityLabel(Text("Sign in button"))
  }
}

#endif
