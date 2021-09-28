//
//  AuthenticationViewModel.swift
//  GSI-Swift-Sample
//
//  Created by Matt Mathias on 9/20/21.
//

import SwiftUI
import GoogleSignIn

class AuthenticationViewModel: ObservableObject {
  @Published var state: State
  private var authenticator: GoogleSignInAuthenticator {
    return GoogleSignInAuthenticator(authViewModel: self)
  }
  var authorizedScopes: [String] {
    switch state {
    case .signedIn(let user):
      return user.grantedScopes ?? []
    case .signedOut:
      return []
    }
  }

  init() {
    if let user = GIDSignIn.sharedInstance.currentUser {
      self.state = .signedIn(user)
    } else {
      self.state = .signedOut
    }
  }

  func signIn() {
    authenticator.signIn()
  }

  func signOut() {
    authenticator.signOut()
  }

  func addContactsReadOnlyScope(completion: @escaping () -> Void) {
    authenticator.addContactsReadOnlyScope(completion: completion)
  }

  func disconnect() {
    authenticator.disconnect()
  }
}

extension AuthenticationViewModel {
  enum State {
    case signedIn(GIDGoogleUser)
    case signedOut
  }
}
