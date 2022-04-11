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

import GoogleSignIn
import SwiftUI

struct UserProfileImageView: View {
  @ObservedObject var userProfileImageLoader: UserProfileImageLoader

  init(userProfile: GIDProfileData) {
    self.userProfileImageLoader = UserProfileImageLoader(userProfile: userProfile)
  }

  var body: some View {
    #if os(iOS)
    Image(uiImage: userProfileImageLoader.image)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(width: 45, height: 45, alignment: .center)
      .scaledToFit()
      .clipShape(Circle())
      .accessibilityLabel(Text("User profile image."))
    #elseif os(macOS)
    Image(nsImage: userProfileImageLoader.image)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(width: 45, height: 45, alignment: .center)
      .scaledToFit()
      .clipShape(Circle())
      .accessibilityLabel(Text("User profile image."))
    #endif
  }
}
