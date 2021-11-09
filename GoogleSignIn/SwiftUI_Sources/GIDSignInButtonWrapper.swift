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

/// A wrapper for `GIDSignInButton` so that it can be used in SwiftUI.
@available(iOS 13.0, *)
public struct GIDSignInButtonWrapper: UIViewRepresentable {
  public let handler: () -> Void

  public init(handler: @escaping () -> Void) {
    self.handler = handler
  }

  public func makeCoordinator() -> Coordinator {
    return Coordinator()
  }

  public func makeUIView(context: Context) -> GIDSignInButton {
    let signInButton = GIDSignInButton()
    signInButton.addTarget(context.coordinator,
                           action: #selector(Coordinator.callHandler),
                           for: .touchUpInside)
    return signInButton
  }

  public func updateUIView(_ uiView: UIViewType, context: Context) {
    context.coordinator.handler = handler
  }
}

@available(iOS 13.0, *)
public extension GIDSignInButtonWrapper {
  class Coordinator {
    var handler: (() -> Void)?

    @objc func callHandler() {
      handler?()
    }
  }
}
