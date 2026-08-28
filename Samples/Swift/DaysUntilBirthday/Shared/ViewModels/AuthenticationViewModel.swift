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
import GTMAppAuth
import AppAuth

/// A class conforming to `ObservableObject` used to represent a user's authentication status.
final class AuthenticationViewModel: ObservableObject {
  /// The user's log in status.
  /// - note: This will publish updates when its value changes.
  @Published var state: State {
    didSet {
      logTestState(event: "state_changed")
    }
  }
  private var authenticator: GoogleSignInAuthenticator {
    return GoogleSignInAuthenticator(authViewModel: self)
  }

  /// The user's `claims` as found in `idToken`.
  /// - note: If the user is logged out, then this will default to empty.
  var claims: [Claim] {
    switch state {
    case .signedIn(let user):
      guard let idToken = user.idToken?.tokenString else { return [] }
      return decodeClaims(fromJwt: idToken)
    case .signedOut:
      return []
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
    if UserDefaults.standard.bool(forKey: "GSITestSignOutOnLaunch") {
      GIDSignIn.sharedInstance.signOut()
      NSLog("GSI test hook: signed out on launch")
    }
    if let user = GIDSignIn.sharedInstance.currentUser {
      self.state = .signedIn(user)
    } else {
      self.state = .signedOut
    }
    logTestState(event: "launch")
    if UserDefaults.standard.bool(forKey: "GSITestForceRefreshOnLaunch") {
      DispatchQueue.main.async { [weak self] in
        self?.forceTokenRefresh()
      }
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

  /// Logs the current authentication state for automated testing.
  /// - parameter event: The name of the event being logged.
  func logTestState(event: String) {
    var signedIn = false
    var hasRefreshToken = false
    var scopeCount = 0
    var expiration = "none"

    if case .signedIn(let user) = state {
      signedIn = true
      hasRefreshToken = !user.refreshToken.tokenString.isEmpty
      scopeCount = user.grantedScopes?.count ?? 0
      if let date = user.accessToken.expirationDate {
        expiration = ISO8601DateFormatter().string(from: date)
      }
    }

    NSLog("GSI_TEST_STATE event=\(event) signedIn=\(signedIn ? 1 : 0) " +
          "refreshToken=\(hasRefreshToken ? 1 : 0) scopes=\(scopeCount) " +
          "expires=\(expiration)")
  }

  /// Forces a token refresh for automated testing.
  func forceTokenRefresh() {
    guard case .signedIn(let user) = state else {
      NSLog("GSI test hook: force refresh skipped, not signed in")
      return
    }
    guard let authSession = user.fetcherAuthorizer as? AuthSession else {
      NSLog("GSI test hook: fetcherAuthorizer is not an AuthSession")
      return
    }

    authSession.authState.setNeedsTokenRefresh()
    authSession.authState.performAction { [weak self] _, _, error in
      DispatchQueue.main.async {
        if let error = error {
          NSLog("GSI test hook: force refresh failed: \(error)")
        } else {
          NSLog("GSI test hook: force refresh succeeded")
        }
        self?.logTestState(event: "force_refresh")
      }
    }
  }
}

private extension AuthenticationViewModel {
  /// Returns a collection of formatted claim keys and values decoded from a JWT.
  func decodeClaims(fromJwt jwt: String) -> [Claim] {
    let segments = jwt.components(separatedBy: ".")

    guard segments.count > 1,
      let payload = decodeJWTSegment(segments[1])
    else {
      return []
    }

    let claims: [Claim?] = [
      formatAuthTime(from: payload),
      formatAmr(from: payload)
    ]

    return claims.compactMap { $0 }
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

  /// Returns the `auth_time` claim from the given JWT, if present.
  func formatAuthTime(from payload: [String: Any]) -> Claim? {
    guard let authTime = payload["auth_time"] as? TimeInterval
    else {
      return nil
    }
    let date = Date(timeIntervalSince1970: authTime)
    let formattedDate = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)
    return Claim(key: "auth_time", value: formattedDate)
  }

  /// Returns the `amr` claim from the given JWT, if present.
  private func formatAmr(from payload: [String: Any]) -> Claim? {
    guard let amr = payload["amr"] as? [String]
    else {
      return nil
    }
    return Claim(key: "amr", value: amr.joined(separator: ", "))
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
