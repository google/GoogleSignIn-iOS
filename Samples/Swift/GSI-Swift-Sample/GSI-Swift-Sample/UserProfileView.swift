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
  @StateObject var contactsViewModel = ContactsViewModel()
  private var user: GIDGoogleUser? {
    return GIDSignIn.sharedInstance.currentUser
  }

  var body: some View {
    if let userProfile = user?.profile {
      VStack {
        HStack(alignment: .top) {
          Spacer().frame(width: 8)
          UserProfileImageView(userProfile: userProfile)
          VStack(alignment: .leading) {
            Text(userProfile.name)
            Text(userProfile.email)
              .foregroundColor(.gray)
          }
          Spacer()
        }
        let cv = ContactsView(userProfile: userProfile, contactsViewModel: contactsViewModel)
        NavigationLink(NSLocalizedString("View Contacts", comment: "View Contacts button"),
                       destination: cv.onAppear {
          guard !self.authViewModel.authorizedScopes.contains(ContactsLoader.contactsReadonlyScope) else {
            print("User has already granted the scope!")
            return
          }
          self.authViewModel.addContactsReadOnlyScope {
            contactsViewModel.fetchContacts()
          }
        })
        Spacer()
      }
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button(NSLocalizedString("Disconnect", comment: "Disconnect button"), action: disconnect)
          Button(NSLocalizedString("Sign Out", comment: "Sign out button"), action: signOut)
        }
      }
      .navigationTitle(NSLocalizedString("User Profile", comment: "User profile navigation title"))
    } else {
      Text(NSLocalizedString("Failed to get user profile!", comment: "Empty user profile text"))
    }
  }

  func disconnect() {
    authViewModel.disconnect()
  }

  func signOut() {
    authViewModel.signOut()
  }
}
