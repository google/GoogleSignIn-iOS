//
//  UserProfileImageView.swift
//  GSI-Swift-Sample
//
//  Created by Matt Mathias on 9/21/21.
//

import GoogleSignIn
import SwiftUI

struct UserProfileImageView: View {
  @ObservedObject var userProfileImageLoader: UserProfileImageLoader
  @State var image = UIImage()

  init(userProfile: GIDProfileData) {
    self.userProfileImageLoader = UserProfileImageLoader(userProfile: userProfile)
  }

  var body: some View {
    Image(uiImage: image)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(width: 45, height: 45, alignment: .center)
      .scaledToFit()
      .clipShape(Circle())
      .onReceive(userProfileImageLoader.didChange) { imageData in
        self.image = UIImage(data: imageData) ?? UIImage()
      }
  }
}
