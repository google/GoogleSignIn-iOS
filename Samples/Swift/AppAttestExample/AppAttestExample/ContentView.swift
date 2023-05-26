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

  var body: some View {
    VStack {
      GoogleSignInButton {
        self.userInfo = ""
        guard let foregroundWindows = UIApplication.shared.connectedScenes
          .filter({ $0.activationState == .foregroundActive })
          .first(where: { $0 is UIWindowScene })
          .flatMap({ ($0 as? UIWindowScene)?.windows }),
              let keyWindow = foregroundWindows.first(where: { $0.isKeyWindow }),
                let rootViewController = keyWindow.rootViewController else {
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
      Text(userInfo)
    }
    .padding()
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
