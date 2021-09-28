//
//  ContentView.swift
//  GSI-Swift-Sample
//
//  Created by Matt Mathias on 9/28/21.
//

import SwiftUI
import GoogleSignIn

struct ContentView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel

  var body: some View {
    return Group {
      switch authViewModel.state {
      case .signedIn:
        NavigationView {
          UserProfileView()
        }
        .animation(.easeInOut)
        .transition(.move(edge: .leading))
      case .signedOut:
        NavigationView {
          SignInView()
        }
      }
    }
  }
}
