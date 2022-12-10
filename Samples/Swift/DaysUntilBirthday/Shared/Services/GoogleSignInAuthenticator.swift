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

import Foundation
import GoogleSignIn
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// An observable class for authenticating via Google.
final class GoogleSignInAuthenticator {
  private var authViewModel: AuthenticationViewModel

  /// Creates an instance of this authenticator.
  /// - parameter authViewModel: The view model this authenticator will set logged in status on.
  init(authViewModel: AuthenticationViewModel) {
    self.authViewModel = authViewModel
  }

#if os(iOS)
  /// Signs in the user based upon the selected account.
  /// - parameter rootViewController: The `UIViewController` to use during the sign in flow.
  /// - returns: The `GIDSignInResult`.
  /// - throws: Any error that may arise during the sign in process.
  @MainActor
  func signIn(with rootViewController: UIViewController) async throws -> GIDSignInResult {
    return try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
  }
#endif

#if os(macOS)
  /// Signs in the user based upon the selected account.
  /// - parameter window: The `NSWindow` to use during the sign in flow.
  /// - returns: The `GIDSignInResult`.
  /// - throws: Any error that may arise during the sign in process.
  @MainActor
  func signIn(with window: NSWindow) async throws -> GIDSignInResult {
    return try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
  }
#endif

  /// Signs out the current user.
  func signOut() {
    GIDSignIn.sharedInstance.signOut()
    authViewModel.state = .signedOut
  }

  /// Disconnects the previously granted scope and signs the user out.
  @MainActor
  func disconnect() async throws {
    try await GIDSignIn.sharedInstance.disconnect()
    authViewModel.state = .signedOut
  }

#if os(iOS)
  /// Adds the birthday read scope for the current user.
  /// - parameter viewController: The `UIViewController` to use while authorizing the scope.
  /// - returns: The `GIDSignInResult`.
  /// - throws: Any error that may arise while authorizing the scope.
  @MainActor
  func addBirthdayReadScope(viewController: UIViewController) async throws -> GIDSignInResult {
    guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
      fatalError("No currentUser!")
    }
    return try await currentUser.addScopes(
      [BirthdayLoader.birthdayReadScope],
      presenting: viewController
    )
  }
#endif

#if os(macOS)
  /// Adds the birthday read scope for the current user.
  /// - parameter window: The `NSWindow` to use while authorizing the scope.
  /// - returns: The `GIDSignInResult`.
  /// - throws: Any error that may arise while authorizing the scope.
  @MainActor
  func addBirthdayReadScope(window: NSWindow) async throws -> GIDSignInResult {
    guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
      fatalError("No currentUser!")
    }
    return try await currentUser.addScopes(
      [BirthdayLoader.birthdayReadScope],
      presenting: window
    )
  }
#endif
}

extension GoogleSignInAuthenticator {
  enum Error: Swift.Error {
    case failedToSignIn
    case failedToAddBirthdayReadScope(Swift.Error)
    case userUnexpectedlyNilWhileAddingBirthdayReadScope
  }
}
