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

import SwiftUI

// MARK: - Sizing Constants

/// The corner radius of the button
let googleCornerRadius: CGFloat = 2

/// The standard height of the sign in button.
let buttonHeight: CGFloat = 40

/// The width of the icon part of the button in points.
let iconWidth: CGFloat = 40

/// The padding to be applied to the Google icon image.
let iconPadding: CGFloat = 2

/// Left and right text padding.
let textPadding: CGFloat = 14

// MARK: - Font

/// The name of the font for button text.
let fontNameRobotoBold = "Roboto-Bold"

/// Sign-in button text font size.
let fontSize: CGFloat = 14

// MARK: - Icon Image

let googleImageName = "google"

// MARK: - Button Style

/// The layout styles supported by the sign-in button.
///
/// The minimum size of the button depends on the language used for text.
/// The following dimensions (in points) fit for all languages:
/// - standard: 230 x 48
/// - wide:     312 x 48
/// - icon:     48 x 48 (no text, fixed size)
@available(iOS 13.0, macOS 10.15, *)
public enum GoogleSignInButtonStyle {
  case standard
  case wide
  case icon
}

// MARK: - Button Color Scheme

/// The color schemes supported by the sign-in button.
@available(iOS 13.0, macOS 10.15, *)
public enum GoogleSignInButtonColorScheme {
  case dark
  case light
}

// MARK: - Button State

/// The state of the sign-in button.
@available(iOS 13.0, macOS 10.15, *)
public enum GoogleSignInButtonState {
  case normal
  case disabled
  case pressed
}

// MARK: - Colors

// All colors in hex RGBA format (0xRRGGBBAA)

let googleBlue = 0x4285f4ff;
let googleDarkBlue = 0x3367d6ff;
let white = 0xffffffff;
let lightestGrey = 0x00000014;
let lightGrey = 0xeeeeeeff;
let disabledGrey = 0x00000066;
let darkestGrey = 0x00000089;

/// Helper type to calculate foreground color for text.
@available(iOS 13.0, macOS 10.15, *)
private struct ForegroundColor {
  let scheme: GoogleSignInButtonColorScheme
  let state: GoogleSignInButtonState

  var color: Color {
    switch (scheme, state) {
    case (.dark, .normal):
      return Color(hex: white)
    case (.light, .normal):
      return Color(hex: darkestGrey)
    case (_, .disabled):
      return Color(hex: disabledGrey)
    case (.dark, .pressed):
      return Color(hex: white)
    case (.light, .pressed):
      return Color(hex: darkestGrey)
    }
  }
}

/// Helper type to calculate background color for view.
@available(iOS 13.0, macOS 10.15, *)
private struct BackgroundColor {
  let scheme: GoogleSignInButtonColorScheme
  let state: GoogleSignInButtonState

  var color: Color {
    switch (scheme, state) {
    case (.dark, .normal):
      return Color(hex: googleBlue)
    case (.light, .normal):
      return Color(hex: white)
    case (_, .disabled):
      return Color(hex: lightestGrey)
    case (.dark, .pressed):
      return Color(hex: googleDarkBlue)
    case (.light, .pressed):
      return Color(hex: lightGrey)
    }
  }
}

/// Helper type to calculate background color for the icon.
@available(iOS 13.0, macOS 10.15, *)
private struct IconBackgroundColor {
  let scheme: GoogleSignInButtonColorScheme
  let state: GoogleSignInButtonState

  var color: Color {
    switch (scheme, state) {
    case (.light, .pressed), (_, .disabled):
      return Color(hex: lightGrey)
    default:
      return Color(hex: white)
    }
  }
}

/// A type calculating the background and foreground (text) colors of the
/// sign-in button.
@available(iOS 13.0, macOS 10.15, *)
struct SignInButtonColor {
  let scheme: GoogleSignInButtonColorScheme
  let state: GoogleSignInButtonState

  var iconColor: Color {
    let ibc = IconBackgroundColor(scheme: scheme, state: state)
    return ibc.color
  }

  // Icon's border should always match background regardless of state
  var iconBorderColor: Color {
    return backgroundColor
  }

  var foregroundColor: Color {
    let fc = ForegroundColor(scheme: scheme, state: state)
    return fc.color
  }

  var backgroundColor: Color {
    let bc = BackgroundColor(scheme: scheme, state: state)
    return bc.color
  }
}

@available(iOS 13.0, macOS 10.15, *)
extension Color {
  init(hex: Int) {
    self.init(
      red: Double((hex & 0xff000000) >> 24) / 255,
      green: Double((hex & 0x00ff0000) >> 16) / 255,
      blue: Double((hex & 0x0000ff00) >> 8)  / 255,
      opacity: Double((hex & 0x000000ff) >> 0) / 255
    )
  }
}

// MARK: - Custom Width

@available(iOS 13.0, macOS 10.15, *)
fileprivate struct Width {
  let min, max: CGFloat
}

// MARK: - Width and Text By Button Style

@available(iOS 13.0, macOS 10.15, *)
extension GoogleSignInButtonStyle {
  fileprivate var width: Width {
    switch self {
    case .icon: return Width(min: iconWidth, max: iconWidth)
    case .standard: return Width(min: 90, max: .infinity)
    case .wide: return Width(min: 170, max: .infinity)
    }
  }

  private var buttonStrings: GoogleSignInButtonString {
    return GoogleSignInButtonString()
  }

  var buttonText: String {
    switch self {
    case .wide: return buttonStrings.localizedWideButtonText
    case .standard: return buttonStrings.localizedStandardButtonText
    case .icon: return ""
    }
  }
}

// MARK: - Button Style

@available(iOS 13.0, macOS 10.15, *)
struct SwiftUIButtonStyle: ButtonStyle {
  let style: GoogleSignInButtonStyle
  let state: GoogleSignInButtonState
  let scheme: GoogleSignInButtonColorScheme

  /// A computed property vending the button's foreground and background colors.
  var colors: SignInButtonColor {
    return SignInButtonColor(scheme: scheme, state: state)
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(minWidth: style.width.min,
             maxWidth: style.width.max,
             minHeight: buttonHeight,
             maxHeight: buttonHeight)
      .background(colors.backgroundColor)
      .foregroundColor(colors.foregroundColor)
      .cornerRadius(googleCornerRadius)
      .shadow(
        color: state == .disabled ? .clear : .gray,
        radius: googleCornerRadius, x: 0, y: 2
      )
  }
}
