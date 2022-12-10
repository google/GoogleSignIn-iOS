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
#if os(iOS)
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      print("There is no root view controller!")
      return
    }
#elseif os(macOS)
    guard let presentingWindow = NSApplication.shared.windows.first else {
      print("There is no presenting window!")
      return
    }
#endif

    Task { @MainActor in
      do {
#if os(iOS)
        let signInResult = try await authenticator.signIn(with: rootViewController)
#elseif os(macOS)
        let signInResult = try await authenticator.signIn(with: presentingWindow)
#endif
        self.state = .signedIn(signInResult.user)
      } catch {
        print("Error signing in: \(error)")
      }
    }
  }

  /// Signs the user out.
  func signOut() {
    authenticator.signOut()
  }

  /// Disconnects the previously granted scope and signs the user out.
  func disconnect() {
    Task { @MainActor in
      do {
        try await authenticator.disconnect()
      } catch {
        print("Error disconnecting: \(error)")
      }
    }
  }

  var hasBirthdayReadScope: Bool {
    return authorizedScopes.contains(BirthdayLoader.birthdayReadScope)
  }

#if os(iOS)
  /// Adds the requested birthday read scope.
  /// - parameter viewController: A `UIViewController` to use while presenting the flow.
  /// - returns: The `GIDSignInResult`.
  /// - throws: Any error that may arise while adding the read birthday scope.
  func addBirthdayReadScope(viewController: UIViewController) async throws -> GIDSignInResult {
    return try await authenticator.addBirthdayReadScope(viewController: viewController)
  }
#endif


#if os(macOS)
  /// adds the requested birthday read scope.
  /// - parameter window: An `NSWindow` to use while presenting the flow.
  /// - returns: The `GIDSignInResult`.
  /// - throws: Any error that may arise while adding the read birthday scope.
  func addBirthdayReadScope(window: NSWindow) async throws -> GIDSignInResult {
    return try await authenticator.addBirthdayReadScope(window: window)
  }
#endif
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
