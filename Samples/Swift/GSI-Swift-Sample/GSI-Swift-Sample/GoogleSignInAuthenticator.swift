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

class GoogleSignInAuthenticator: ObservableObject {
  private let clientID = "256442014139-g0adlfr889u4k71ok75k2tnf0t4bgepb.apps.googleusercontent.com"

  private lazy var configuration: GIDConfiguration = {
    return GIDConfiguration(clientID: clientID)
  }()

  private var authViewModel: AuthenticationViewModel

  init(authViewModel: AuthenticationViewModel) {
    self.authViewModel = authViewModel
  }

  func signIn() {
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      print("There is no root view controller!")
      return
    }
    GIDSignIn.sharedInstance.signIn(with: configuration,
                                    presenting: rootViewController) { user, error in
      guard let user = user else {
        print("Error! \(String(describing: error))")
        return
      }
      print("Signed in with user: \(user)")
      self.authViewModel.state = .signedIn(user)
    }
  }

  func signOut() {
    GIDSignIn.sharedInstance.signOut()
    authViewModel.state = .signedOut
  }

  func addContactsReadOnlyScope(completion: @escaping () -> Void) {
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      fatalError("No root view controller!")
    }

    GIDSignIn.sharedInstance.addScopes([ContactsLoader.contactsReadonlyScope],
                                       presenting: rootViewController) { user, error in
      if let error = error {
        print("Found error while adding contacts readonly scope: \(error).")
        return
      }

      guard let currentUser = GIDSignIn.sharedInstance.currentUser else { return }
      self.authViewModel.state = .signedIn(currentUser)
      completion()
    }
  }

  func disconnect() {
    GIDSignIn.sharedInstance.disconnect { error in
      if let error = error {
        print("Encountered error disconnecting scope: \(error).")
      }
      self.signOut()
    }
  }
}
