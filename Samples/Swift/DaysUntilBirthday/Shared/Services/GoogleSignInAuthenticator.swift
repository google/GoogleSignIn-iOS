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

/// An observable class for authenticating via Google.
final class GoogleSignInAuthenticator: ObservableObject {
  private var authViewModel: AuthenticationViewModel

  /// Creates an instance of this authenticator.
  /// - parameter authViewModel: The view model this authenticator will set logged in status on.
  init(authViewModel: AuthenticationViewModel) {
    self.authViewModel = authViewModel
  }

  /// Signs in the user based upon the selected account.'
  /// - note: Successful calls to this will set the `authViewModel`'s `state` property.
  func signIn() {
#if os(iOS)
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      print("There is no root view controller!")
      return
    }

    GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
      guard let signInResult = signInResult else {
        print("Error! \(String(describing: error))")
        return
      }
      self.authViewModel.state = .signedIn(signInResult.user)
    }

#elseif os(macOS)
    guard let presentingWindow = NSApplication.shared.windows.first else {
      print("There is no presenting window!")
      return
    }

    GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) { signInResult, error in
      guard let signInResult = signInResult else {
        print("Error! \(String(describing: error))")
        return
      }
      self.authViewModel.state = .signedIn(signInResult.user)
    }
#endif
  }

  /// Signs out the current user.
  func signOut() {
    GIDSignIn.sharedInstance.signOut()
    authViewModel.state = .signedOut
  }

  /// Disconnects the previously granted scope and signs the user out.
  func disconnect() {
    GIDSignIn.sharedInstance.disconnect { error in
      if let error = error {
        print("Encountered error disconnecting scope: \(error).")
      }
      self.signOut()
    }
  }

  // Confines birthday calucation to iOS for now.
  /// Adds the birthday read scope for the current user.
  /// - parameter completion: An escaping closure that is called upon successful completion of the
  /// `addScopes(_:presenting:)` request.
  /// - note: Successful requests will update the `authViewModel.state` with a new current user that
  /// has the granted scope.
  func addBirthdayReadScope(completion: @escaping () -> Void) {
    guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
      fatalError("No user signed in!")
    }
    
    #if os(iOS)
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      fatalError("No root view controller!")
    }

    currentUser.addScopes([BirthdayLoader.birthdayReadScope],
                          presenting: rootViewController) { signInResult, error in
      if let error = error {
        print("Found error while adding birthday read scope: \(error).")
        return
      }

      guard let signInResult = signInResult else { return }
      self.authViewModel.state = .signedIn(signInResult.user)
      completion()
    }

    #elseif os(macOS)
    guard let presentingWindow = NSApplication.shared.windows.first else {
      fatalError("No presenting window!")
    }

    currentUser.addScopes([BirthdayLoader.birthdayReadScope],
                          presenting: presentingWindow) { signInResult, error in
      if let error = error {
        print("Found error while adding birthday read scope: \(error).")
        return
      }

      guard let signInResult = signInResult else { return }
      self.authViewModel.state = .signedIn(signInResult.user)
      completion()
    }

    #endif
  }

}
