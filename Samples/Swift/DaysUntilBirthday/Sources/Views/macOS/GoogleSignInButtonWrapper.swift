import SwiftUI

struct GoogleSignInButtonWrapper: View {
  let handler: () -> Void

  var body: some View {
    Button(action: {
      handler()
    }) {
      Text("SIGN IN")
          .frame(width: 100 , height: 50, alignment: .center)
    }
     .background(Color.blue)
     .foregroundColor(Color.white)
     .cornerRadius(5)
  }
}
