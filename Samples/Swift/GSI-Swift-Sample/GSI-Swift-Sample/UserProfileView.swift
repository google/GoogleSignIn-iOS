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
  @StateObject var birthdayViewModel = BirthdayViewModel()
  private var user: GIDGoogleUser? {
    return GIDSignIn.sharedInstance.currentUser
  }

  var body: some View {
    return Group {
      if let userProfile = user?.profile {
        VStack {
          HStack(alignment: .top) {
            Spacer().frame(width: 8)
            UserProfileImageView(userProfile: userProfile)
            VStack(alignment: .leading) {
              Text(userProfile.name)
                .accessibility(hint: Text("Logged in user name."))
              Text(userProfile.email)
                .accessibility(hint: Text("Logged in user email."))
                .foregroundColor(.gray)
            }
            Spacer()
          }
          NavigationLink(NSLocalizedString("View Days Until Birthday", comment: "View birthday days"),
                         destination: BirthdayView(birthdayViewModel: birthdayViewModel).onAppear {
            if !self.authViewModel.hasBirthdayReadScope {
              self.authViewModel.addBirthdayReadScope {
                self.birthdayViewModel.fetchBirthday()
              }
            } else {
              print("User has already granted the scope!")
              self.birthdayViewModel.fetchBirthday()
            }
          })
            .accessibility(hint: Text("View days until birthday navigation button."))
          Spacer()
        }
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(NSLocalizedString("Disconnect", comment: "Disconnect button"), action: disconnect)
              .accessibility(hint: Text("Disconnect scope."))
              .disabled(!authViewModel.hasBirthdayReadScope)
            Button(NSLocalizedString("Sign Out", comment: "Sign out button"), action: signOut)
              .accessibility(hint: Text("Sign out button"))
          }
        }
      } else {
        Text(NSLocalizedString("Failed to get user profile!", comment: "Empty user profile text"))
          .accessibility(hint: Text("Failed to get user profile"))
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
