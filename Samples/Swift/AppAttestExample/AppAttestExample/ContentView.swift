/*
 * Copyright 2023 Google LLC
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
import GoogleSignInSwift

struct ContentView: View {
  @State private var userInfo = ""
  @State private var birthday = ""
  @State private var shouldPresentAlert = false
  @State private var errorInfo: ErrorInfo?

  var body: some View {
    NavigationStack {
      VStack {
        HStack {
          GoogleSignInButton {
            self.userInfo = ""
            guard let rootViewController = self.rootViewController else {
              print("No root view controller")
              return
            }
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
              guard let result else {
                print("Error signing in: \(String(describing: error))")
                return
              }
              print("Successfully signed in user")
              self.userInfo = result.user.profile?.json ?? ""
            }
          }
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button(NSLocalizedString("Sign out", comment: "sign out")) {
                GIDSignIn.sharedInstance.signOut()
                clearState()
              }
              .disabled(userInfo.isEmpty)
            }
            ToolbarItem(placement: .navigationBarLeading) {
              Button(NSLocalizedString("Disconnect", comment: "disconnect")) {
                GIDSignIn.sharedInstance.disconnect { error in
                  if let error {
                    print("Disconnection error: \(error)")
                    return
                  }
                  print("Disconnected")
                  clearState()
                }
              }
              .disabled(shouldDisableDisconnect)
            }
            ToolbarItem(placement: .bottomBar) {
              Button(NSLocalizedString("Add Birthday Scope", comment: "Add Scope Button")) {
                guard let rvc = rootViewController else {
                  print("No root view controller to use as presenter")
                  return
                }
                GIDSignIn.sharedInstance.currentUser?.addScopes(
                  ["https://www.googleapis.com/auth/user.birthday.read"],
                  presenting: rvc
                ) { result, error in
                  shouldPresentAlert = true
                  if let result {
                    print("Successfully added scope: \(result)")
                    errorInfo = ErrorInfo.success
                    return
                  }
                  if let e = error {
                    print("Failed to add scope: \(e)")
                    if (e as NSError).code == GIDSignInError.scopesAlreadyGranted.rawValue {
                      errorInfo = ErrorInfo(
                        errorDescription: NSLocalizedString(
                          "Did not add scope",
                          comment: "no scope"
                        ),
                        failureReason: NSLocalizedString(
                          "User already added scope.",
                          comment: "already added scope"
                        )
                      )
                    } else {
                      errorInfo = ErrorInfo.unkownError
                    }
                    return
                  }
                }
              }
              .disabled(userInfo.isEmpty)
            }
          }
          .alert(
            isPresented: $shouldPresentAlert,
            error: errorInfo) { info in
              Text(info.errorDescription ?? "Unknown Alert")
            } message: { info in
              Text(info.failureReason ?? "NA")
            }
        }
        Text(userInfo)
      }
      .padding()
    }
  }
}

private extension ContentView {
  var rootViewController: UIViewController? {
    return UIApplication.shared.connectedScenes
      .filter({ $0.activationState == .foregroundActive })
      .compactMap { $0 as? UIWindowScene }
      .compactMap { $0.keyWindow }
      .first?.rootViewController
  }

  var shouldDisableDisconnect: Bool {
    guard !userInfo.isEmpty else {
      return true
    }
    return GIDSignIn.sharedInstance.currentUser?.grantedScopes?.isEmpty ?? false
  }

  func clearState() {
    errorInfo = nil
    shouldPresentAlert = false
    userInfo = ""
  }
}

private extension GIDProfileData {
  var json: String {
    """
    success: {
      Given Name: \(self.givenName ?? "None")
      Family Name: \(self.familyName ?? "None")
      Name: \(self.name)
      Email: \(self.email)
      Profile Photo: \(self.imageURL(withDimension: 1)?.absoluteString ?? "None");
    }
    """
  }
}

fileprivate struct ErrorInfo: LocalizedError {
  static var unkownError: ErrorInfo {
    return ErrorInfo(
      errorDescription: NSLocalizedString("Unkown Error!", comment: "unknown error"),
      failureReason: NSLocalizedString("NA", comment: "NA error string")
    )
  }
  static var success: ErrorInfo {
    return ErrorInfo(
      errorDescription: NSLocalizedString("Successfully!", comment: "no error"),
      failureReason: NSLocalizedString("Added birthday read scope.", comment: "scope added")
    )
  }
  var errorDescription: String?
  var failureReason: String?
  var recoverySuggestion: String?
  var helpAnchor: String?
}
