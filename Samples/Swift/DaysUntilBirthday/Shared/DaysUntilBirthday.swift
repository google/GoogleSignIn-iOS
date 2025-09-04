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

@main
struct DaysUntilBirthday: App {
  @StateObject var authViewModel = AuthenticationViewModel()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(authViewModel)
        .onAppear {
          GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
              print("✅ Session restored for user: \(user.profile?.name ?? "Unknown")")
              print("Token %@", user.idToken?.tokenString ?? "NULL")
              self.authViewModel.authTime = user.authTime
              self.authViewModel.state = .signedIn(user)
            } else if let error = error {
              self.authViewModel.state = .signedOut
              print("There was an error restoring the previous sign-in: \(error)")
            } else {
              self.authViewModel.state = .signedOut
            }
          }
        }
        .onOpenURL { url in
          GIDSignIn.sharedInstance.handle(url)
        }
    }
  }
}

import Foundation // Make sure to add this import for the new code

// This extension adds the .authTime property to the GIDGoogleUser object
extension GIDGoogleUser {
  var authTime: Date? {
    guard let idToken = self.idToken?.tokenString,
          let payload = JWTDecoder.decode(jwtToken: idToken),
          let authTimeInterval = payload["auth_time"] as? TimeInterval else {
      return nil
    }
    return Date(timeIntervalSince1970: authTimeInterval)
  }
}

// This is a helper utility that the extension uses to decode the token
struct JWTDecoder {
    static func decode(jwtToken jwt: String) -> [String: Any]? {
        let segments = jwt.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        var base64 = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        guard let bodyData = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
              let json = try? JSONSerialization.jsonObject(with: bodyData, options: []),
              let payload = json as? [String: Any] else {
            return nil
        }
        return payload
    }
}
