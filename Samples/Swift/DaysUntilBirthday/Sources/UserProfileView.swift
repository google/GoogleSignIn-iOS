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

struct UserProfileView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  #if os(iOS)
  @StateObject var birthdayViewModel = BirthdayViewModel()
  #endif
  private var user: GIDGoogleUser? {
    return GIDSignIn.sharedInstance.currentUser
  }

  var body: some View {
    return Group {
      if let userProfile = user?.profile {
        VStack {
          HStack(alignment: .top) {
            UserProfileImageView(userProfile: userProfile)
              .padding(.leading)
            VStack(alignment: .leading) {
              Text(userProfile.name)
                .accessibilityLabel(Text("User name."))
              Text(userProfile.email)
                .accessibilityLabel(Text("User email."))
                .foregroundColor(.gray)
            }
            Spacer()
          }
          #if os(iOS)
          NavigationLink(NSLocalizedString("View Days Until Birthday", comment: "View birthday days"),
                         destination: BirthdayView(birthdayViewModel: birthdayViewModel).onAppear {
            guard self.birthdayViewModel.birthday != nil else {
              if !self.authViewModel.hasBirthdayReadScope {
                self.authViewModel.addBirthdayReadScope {
                  self.birthdayViewModel.fetchBirthday()
                }
              } else {
                self.birthdayViewModel.fetchBirthday()
              }
              return
            }
          })
            .accessibilityLabel(Text("View days until birthday."))
          Spacer()
          #endif
        }
        .toolbar {
          #if os(iOS)
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(NSLocalizedString("Disconnect", comment: "Disconnect button"), action: disconnect)
              .accessibilityLabel(Text("Disconnect scope button."))
            Button(NSLocalizedString("Sign Out", comment: "Sign out button"), action: signOut)
              .accessibilityLabel(Text("Sign out button"))
          }
          #elseif os(macOS)
          ToolbarItemGroup(placement: .primaryAction) {
            Button(NSLocalizedString("Disconnect", comment: "Disconnect button"), action: disconnect)
              .accessibilityLabel(Text("Disconnect scope button."))
            Button(NSLocalizedString("Sign Out", comment: "Sign out button"), action: signOut)
              .accessibilityLabel(Text("Sign out button"))
          }
          #endif
        }
      } else {
        Text(NSLocalizedString("Failed to get user profile!", comment: "Empty user profile text"))
          .accessibilityLabel(Text("Failed to get user profile"))
      }
    }
  }

  func disconnect() {
    authViewModel.disconnect()
  }

  func signOut() {
    authViewModel.signOut()
  }
}
