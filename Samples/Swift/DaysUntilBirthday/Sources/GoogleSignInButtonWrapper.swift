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
#if os(iOS)
typealias GIDViewRepresentable = UIViewRepresentable
#else // os(macOS)
typealias GIDViewRepresentable = NSViewRepresentable
#endif

import SwiftUI
import GoogleSignIn

/// A wrapper for `GIDSignInButton` so that it can be used in SwiftUI.
struct GoogleSignInButtonWrapper: GIDViewRepresentable {
  let handler: () -> Void

  init(handler: @escaping () -> Void) {
    self.handler = handler
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }

  #if os(iOS)
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

  #elseif os(macOS)
  func makeNSView(context: Context) -> NSButton {
    let signInButton = NSButton(title: "Sign in",
                                target: context.coordinator,
                                action: #selector(Coordinator.callHandler))

    return signInButton
  }

  func updateNSView(_ nsView: NSButton, context: Context) {
    context.coordinator.handler = handler
  }
  #endif
}

extension GoogleSignInButtonWrapper {
  class Coordinator {
    var handler: (() -> Void)?

    @objc func callHandler() {
      handler?()
    }
  }
}
