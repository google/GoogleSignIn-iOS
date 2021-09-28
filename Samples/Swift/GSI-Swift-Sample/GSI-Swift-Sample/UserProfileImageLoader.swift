//
//  UserProfileImageLoader.swift
//  GSI-Swift-Sample
//
//  Created by Matt Mathias on 9/21/21.
//

import Combine
import SwiftUI
import GoogleSignIn

class UserProfileImageLoader: ObservableObject {
  private let userProfile: GIDProfileData
  var didChange = PassthroughSubject<Data, Never>()
  private let imageLoaderQueue = DispatchQueue(label: "com.google.gsi-swift-sample")

  lazy var imageData: Data? = Data() {
    didSet {
      guard let imageData = imageData else { return }
      didChange.send(imageData)
    }
  }

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
