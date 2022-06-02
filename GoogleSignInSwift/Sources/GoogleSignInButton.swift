/*
 * Copyright 2022 Google LLC
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

#if !arch(arm) && !arch(i386)

import SwiftUI
import CoreGraphics

// MARK: - Sign-In Button

/// A Google Sign In button to be used in SwiftUI.
@available(iOS 13.0, macOS 10.15, *)
public struct GoogleSignInButton: View {
  /// An object containing the styling information needed to create the button.
  @ObservedObject public var viewModel: GoogleSignInButtonViewModel
  private let action: () -> Void
  private let fontLoaded: Bool

  /// Creates an instance of the Google Sign-In button for use in SwiftUI
  /// - parameter viewModel: An instance of `GoogleSignInButtonViewModel`
  ///     containing information on the button's scheme, style, and state.
  ///     Defaults to `GoogleSignInButtonViewModel` with its standard defaults.
  /// - parameter action: A closure to use as the button's action upon press.
  /// - seealso: Refer to `GoogleSignInButtonViewModel.swift` for its defaults.
  public init(
    viewModel: GoogleSignInButtonViewModel = GoogleSignInButtonViewModel(),
    action: @escaping () -> Void
  ) {
    self.viewModel = viewModel
    self.action = action
    self.fontLoaded = Font.loadCGFont()
  }

  /// A convenience initializer to create a Google Sign-In button in SwiftUI
  /// with scheme, style, and state.
  /// - parameter scheme: The `GoogleSignInButtonColorScheme` to use. Defaults
  ///     to `.light`.
  /// - parameter style: The `GoogleSignInButtonStyle` to use. Defaults to
  ///     `.standard`.
  /// - parameter state: The `GoogleSignInButtonState` to use. Defaults to
  ///     `.normal`.
  /// - parameter action: A closure to use as the button's action upon press.
  public init(
    scheme: GoogleSignInButtonColorScheme = .light,
    style: GoogleSignInButtonStyle = .standard,
    state: GoogleSignInButtonState = .normal,
    action: @escaping () -> Void
  ) {
    let vm = GoogleSignInButtonViewModel(
      scheme: scheme,
      style: style,
      state: state
    )
    self.init(viewModel: vm, action: action)
  }

  public var body: some View {
    Button(action: action) {
      switch viewModel.style {
      case .icon:
        ZStack {
          RoundedRectangle(cornerRadius: googleCornerRadius)
            .fill(viewModel.buttonStyle.colors.iconColor)
            .border(viewModel.buttonStyle.colors.iconBorderColor)
          Image.signInButtonImage
        }
      case .standard, .wide:
        HStack(alignment: .center) {
          ZStack {
            RoundedRectangle(cornerRadius: googleCornerRadius)
              .fill(
                viewModel.state == .disabled ?
                  .clear : viewModel.buttonStyle.colors.iconColor
              )
              .frame(
                width: iconWidth - iconPadding,
                height: iconWidth - iconPadding
              )
            Image.signInButtonImage
          }
          .padding(.leading, 1)
          Text(viewModel.style.buttonText)
            .fixedSize()
            .padding(.trailing, textPadding)
            .frame(
              width: viewModel.style.widthForButtonText,
              height: buttonHeight,
              alignment: .leading
            )
          Spacer()
        }
      }
    }
    .font(signInButtonFont)
    .buttonStyle(viewModel.buttonStyle)
    .disabled(viewModel.state == .disabled)
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          guard viewModel.state != .disabled,
                  viewModel.state != .pressed else { return }
          viewModel.state = .pressed
        }
        .onEnded { _ in
          guard viewModel.state != .disabled else { return }
          viewModel.state = .normal
        }
    )
  }
}

// MARK: - Google Icon Image

@available(iOS 13.0, macOS 10.15, *)
private extension Image {
  static var signInButtonImage: Image {
    guard let iconURL = Bundle.urlForGoogleResource(
      name: googleImageName,
      withExtension: "png"
    ) else {
      fatalError("Unable to load Google icon image url: \(Image.Error.unableToLoadGoogleIcon(name: googleImageName))")
    }
#if os(iOS) || targetEnvironment(macCatalyst)
    guard let uiImage = UIImage(contentsOfFile: iconURL.path) else {
      fatalError("Unable to load Google icon image url: \(Image.Error.unableToLoadGoogleIcon(name: googleImageName))")
    }
    return Image(uiImage: uiImage)
#elseif os(macOS)
    guard let nsImage = NSImage(contentsOfFile: iconURL.path) else {
      fatalError("Unable to load Google icon image url: \(Image.Error.unableToLoadGoogleIcon(name: googleImageName))")
    }
    return Image(nsImage: nsImage)
#else
      fatalError("Unrecognized platform for SwiftUI sign in button image")
#endif
  }

  enum Error: Swift.Error {
    case unableToLoadGoogleIcon(name: String)
  }
}


// MARK: - Google Font

@available(iOS 13.0, macOS 10.15, *)
private extension GoogleSignInButton {
  var signInButtonFont: Font {
    guard fontLoaded else {
      return .system(size: fontSize, weight: .bold)
    }
    return .custom(fontNameRobotoBold, size: fontSize)
  }
}

@available(iOS 13.0, macOS 10.15, *)
private extension Font {
  /// Load the font for the button.
  /// - returns A `Bool` indicating whether or not the font was loaded.
  static func loadCGFont() -> Bool {
    // Check to see if the font has already been loaded
#if os(iOS) || targetEnvironment(macCatalyst)
    if let _ = UIFont(name: fontNameRobotoBold, size: fontSize) {
      return true
    }
#elseif os(macOS)
    if let _ = NSFont(name: fontNameRobotoBold, size: fontSize) {
      return true
    }
#else
    fatalError("Unrecognized platform for SwiftUI sign in button font")
#endif
    guard let fontURL = Bundle.urlForGoogleResource(
      name: fontNameRobotoBold,
      withExtension: "ttf"
    ), let dataProvider = CGDataProvider(filename: fontURL.path),
          let newFont = CGFont(dataProvider) else {
            return false
          }
    return CTFontManagerRegisterGraphicsFont(newFont, nil)
  }
}

#endif // !arch(arm) && !arch(i386)
