//
//  GoogleSignInButtonWrapper.swift
//  GSI-Swift-Sample
//
//  Created by Matt Mathias on 9/20/21.
//

import SwiftUI
import GoogleSignIn

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
