//
//  GSI_Swift_SampleApp.swift
//  GSI-Swift-Sample
//
//  Created by Matt Mathias on 9/28/21.
//

import SwiftUI
import GoogleSignIn

@main
struct GSI_Swift_SampleApp: App {
  @StateObject var authViewModel = AuthenticationViewModel()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(authViewModel)
        .onAppear {
          GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
              self.authViewModel.state = .signedIn(user)
            } else if let error = error {
              self.authViewModel.state = .signedOut
              print("There was an error restoring the previous sign-in: \(error)")
            } else {
              self.authViewModel.state = .signedOut
            }
          }
        }
    }
  }
}
