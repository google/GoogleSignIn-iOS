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

struct ContentView: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel

  var body: some View {
    return Group {
      switch authViewModel.state {
      case .signedIn:
#warning("Adding `.navigationViewStyle()` silences the console warnings about failing to satisfy constraints, but suppresses the toolbar items in `UserProfileView`.")
        UserProfileView()
//          .navigationViewStyle(.stack)
          .animation(.easeInOut)
          .transition(.move(edge: .leading))
      case .signedOut:
        SignInView()
          .navigationViewStyle(.stack)
      }
    }
  }
}
