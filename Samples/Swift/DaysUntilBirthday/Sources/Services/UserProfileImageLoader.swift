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

#if os(iOS)
typealias GIDImage = UIImage
#elseif os(macOS)
typealias GIDImage = NSImage
#endif

import Combine
import SwiftUI
import GoogleSignIn

/// An observable class for loading the current user's profile image.
final class UserProfileImageLoader: ObservableObject {
  private let userProfile: GIDProfileData
  private let imageLoaderQueue = DispatchQueue(label: "com.google.days-until-birthday")
  /// A `UIImage` property containing the current user's profile image.
  /// - note: This will default to a placeholder, and updates will be published to subscribers.
  @Published var image = GIDImage(named: "PlaceholderAvatar")!

  /// Creates an instance of this loader with provided user profile.
  /// - note: The instance will asynchronously fetch the image data upon creation.
  init(userProfile: GIDProfileData) {
    self.userProfile = userProfile
    guard userProfile.hasImage else {
      return
    }

    imageLoaderQueue.async {
      #if os(iOS)
      let dimension = 45 * UIScreen.main.scale
      #elseif os(macOS)
      let dimension = 120
      #endif
      guard let url = userProfile.imageURL(withDimension: UInt(dimension)),
            let data = try? Data(contentsOf: url),
            let image = GIDImage(data: data) else {
        return
      }
      DispatchQueue.main.async {
        self.image = image
      }
    }
  }
}
