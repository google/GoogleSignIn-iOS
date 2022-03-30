import SwiftUI

struct GoogleSignInButtonOnMac: View {
  @EnvironmentObject var viewModel: AuthenticationViewModel

  var body: some View {
    Button(action: {
      viewModel.signIn()
    }) {
      Text("SIGN IN")
          .frame(width: 100 , height: 50, alignment: .center)
    }
     .background(Color.blue)
     .foregroundColor(Color.white)
     .cornerRadius(5)
     .accessibilityLabel(Text("Sign in button"))
  }
}
