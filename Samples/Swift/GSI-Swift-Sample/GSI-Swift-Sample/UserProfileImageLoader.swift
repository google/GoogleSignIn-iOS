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

import Combine
import SwiftUI
import GoogleSignIn

/// An observable class for loading the current user's profile image.
final class UserProfileImageLoader: ObservableObject {
  private let userProfile: GIDProfileData

  /// A `PassthroughSubject` that is called when the `imageData` is received.
  var didChange = PassthroughSubject<Data, Never>()
  private let imageLoaderQueue = DispatchQueue(label: "com.google.gsi-swift-sample")

  /// The requested image's `Data`.
  /// - note: The result is lazily loaded and will call `didChange` after it is set.
  lazy var imageData: Data? = Data() {
    didSet {
      guard let imageData = imageData else { return }
      didChange.send(imageData)
    }
  }

  /// Creates an instance of this loader with provided user profile.
  /// - note: The instance will asynchronously fetch the image data upon creation.
  init(userProfile: GIDProfileData) {
    self.userProfile = userProfile
    guard userProfile.hasImage else {
      self.imageData = UIImage(named: "PlaceholderAvatar")?.pngData()
      return
    }

    imageLoaderQueue.async {
      let dimension = 45 * UIScreen.main.scale
      guard let url = userProfile.imageURL(withDimension: UInt(dimension)),
            let data = try? Data(contentsOf: url) else {
        return
      }
      DispatchQueue.main.async {
        self.imageData = data
      }
    }
  }
}
