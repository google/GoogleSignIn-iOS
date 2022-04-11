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

/// A class conforming to `ObservableObject` used to represent a user's authentication status.
final class AuthenticationViewModel: ObservableObject {
  /// The user's log in status.
  /// - note: This will publish updates when its value changes.
  @Published var state: State
  private var authenticator: GoogleSignInAuthenticator {
    return GoogleSignInAuthenticator(authViewModel: self)
  }
  /// The user-authorized scopes.
  /// - note: If the user is logged out, then this will default to empty.
  var authorizedScopes: [String] {
    switch state {
    case .signedIn(let user):
      return user.grantedScopes ?? []
    case .signedOut:
      return []
    }
  }

  /// Creates an instance of this view model.
  init() {
    if let user = GIDSignIn.sharedInstance.currentUser {
      self.state = .signedIn(user)
    } else {
      self.state = .signedOut
    }
  }

  /// Signs the user in.
  func signIn() {
    authenticator.signIn()
  }

  /// Signs the user out.
  func signOut() {
    authenticator.signOut()
  }

  /// Disconnects the previously granted scope and logs the user out.
  func disconnect() {
    authenticator.disconnect()
  }

  var hasBirthdayReadScope: Bool {
    return authorizedScopes.contains(BirthdayLoader.birthdayReadScope)
  }

  /// Adds the requested birthday read scope.
  /// - parameter completion: An escaping closure that is called upon successful completion.
  func addBirthdayReadScope(completion: @escaping () -> Void) {
    authenticator.addBirthdayReadScope(completion: completion)
  }

}

extension AuthenticationViewModel {
  /// An enumeration representing logged in status.
  enum State {
    /// The user is logged in and is the associated value of this case.
    case signedIn(GIDGoogleUser)
    /// The user is logged out.
    case signedOut
  }
}
