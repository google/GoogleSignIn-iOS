//
//  ContactsView.swift
//  GSI-Swift-Sample
//
//  Created by Matt Mathias on 9/21/21.
//

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
