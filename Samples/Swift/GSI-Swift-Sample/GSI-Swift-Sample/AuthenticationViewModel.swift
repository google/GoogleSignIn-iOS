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

final class AuthenticationViewModel: ObservableObject {
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

  func addBirthdayReadScope(completion: @escaping () -> Void) {
    authenticator.addBirthdayReadScope(completion: completion)
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
