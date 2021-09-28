//
//  SignInView.swift
//  GSI-Swift-Sample
//
//  Created by Matt Mathias on 9/20/21.
//

import SwiftUI

struct SignInView: View {
  @EnvironmentObject var viewModel: AuthenticationViewModel

  var body: some View {
    VStack {
      GoogleSignInButtonWrapper(handler: viewModel.signIn)
    }
    .navigationTitle(NSLocalizedString("Sign-in with Google", comment: "Sign-in navigation title"))
  }
}
