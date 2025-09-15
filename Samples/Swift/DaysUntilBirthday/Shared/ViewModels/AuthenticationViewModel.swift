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

  var authTime: Date? {
    switch state {
    case .signedIn(let user):
      guard let idToken = user.idToken?.tokenString else { return nil }
      return decodeAuthTime(fromJWT: idToken)
    case .signedOut:
      return nil
    }
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
  @MainActor func signIn() {
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
  @MainActor func addBirthdayReadScope(completion: @escaping () -> Void) {
      authenticator.addBirthdayReadScope(completion: completion)
  }
  
  var formattedAuthTimeString: String? {
    guard let date = authTime else { return nil }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
    return formatter.string(from: date)
  }
}

private extension AuthenticationViewModel {
  func decodeAuthTime(fromJWT jwt: String) -> Date? {
    let segments = jwt.components(separatedBy: ".")
    guard let parts = decodeJWTSegment(segments[1]),
          let authTimeInterval = parts["auth_time"] as? TimeInterval else {
      return nil
    }
    return Date(timeIntervalSince1970: authTimeInterval)
  }

  func decodeJWTSegment(_ segment: String) -> [String: Any]? {
    guard let segmentData = base64UrlDecode(segment),
          let segmentJSON = try? JSONSerialization.jsonObject(with: segmentData, options: []),
          let payload = segmentJSON as? [String: Any] else {
      return nil
    }
    return payload
  }
  
  func base64UrlDecode(_ value: String) -> Data? {
    var base64 = value
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")

    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
      let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
      base64 = base64 + padding
    }
    return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
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
