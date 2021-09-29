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

struct ContactsView: View {
  private let userProfile: GIDProfileData
  @ObservedObject private var contactsViewModel: ContactsViewModel

  init(userProfile: GIDProfileData, contactsViewModel: ContactsViewModel) {
    self.userProfile = userProfile
    self.contactsViewModel = contactsViewModel
  }
  
  var body: some View {
    List {
      ForEach(contactsViewModel.allContacts) { contact in
        HStack {
          Text(contact.name ?? "<NA>")
          Text(contact.email ?? "<NA>")
            .foregroundColor(.gray)
        }
      }
      if !contactsViewModel.hasAllContacts {
        HStack {
          Spacer()
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .onAppear {
              contactsViewModel.fetchContacts()
            }
          Spacer()
        }
      }
    }
    .navigationTitle(NSLocalizedString("Contacts", comment: "Contacts navigation title"))
  }
}
