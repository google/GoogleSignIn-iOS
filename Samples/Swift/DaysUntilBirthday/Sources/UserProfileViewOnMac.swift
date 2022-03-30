import SwiftUI
import GoogleSignIn

struct UserProfileViewOnMac: View {
  @EnvironmentObject var authViewModel: AuthenticationViewModel
  @StateObject var birthdayViewModel = BirthdayViewModel()
  private var user: GIDGoogleUser? {
    return GIDSignIn.sharedInstance.currentUser
  }

  var body: some View {
    return Group {
      if let userProfile = user?.profile {
        VStack(spacing: 10) {
          HStack(alignment: .top) {
            UserProfileImageView(userProfile: userProfile)
              .padding(.leading)
            VStack(alignment: .leading) {
              Text(userProfile.name)
                .font(.headline)
                .accessibilityLabel(Text("User name."))
              Text(userProfile.email)
                .accessibilityLabel(Text("User email."))
            }
          }
          Button(NSLocalizedString("Sign Out", comment: "Sign out button"), action: signOut)
            .background(Color.blue)
            .foregroundColor(Color.white)
            .cornerRadius(5)
            .accessibilityLabel(Text("Sign out button"))

          Button(NSLocalizedString("Disconnect", comment: "Disconnect button"), action: disconnect)
            .background(Color.blue)
            .foregroundColor(Color.white)
            .cornerRadius(5)
            .accessibilityLabel(Text("Disconnect scope button."))
          Spacer()
          NavigationLink(NSLocalizedString("View Days Until Birthday", comment: "View birthday days"),
                         destination: BirthdayView(birthdayViewModel: birthdayViewModel).onAppear {
            guard self.birthdayViewModel.birthday != nil else {
              if !self.authViewModel.hasBirthdayReadScope {
                self.authViewModel.addBirthdayReadScope {
                  self.birthdayViewModel.fetchBirthday()
                }
              } else {
                self.birthdayViewModel.fetchBirthday()
              }
              return
            }
          })
            .background(Color.blue)
            .foregroundColor(Color.white)
            .cornerRadius(5)
            .accessibilityLabel(Text("View days until birthday."))
          Spacer()
        }
      } else {
        Text(NSLocalizedString("Failed to get user profile!", comment: "Empty user profile text"))
          .accessibilityLabel(Text("Failed to get user profile"))
      }
    }
  }

  func disconnect() {
    authViewModel.disconnect()
  }

  func signOut() {
    authViewModel.signOut()
  }
}
