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

import XCTest
@testable import GoogleSignInSwift

@available(iOS 13.0, macOS 10.15, *)
class GoogleSignInButtonStylingTests: XCTestCase {
  private typealias ButtonViewModelInfo = (
    scheme: GoogleSignInButtonColorScheme,
    style: GoogleSignInButtonStyle,
    state: GoogleSignInButtonState
  )

  func testThatViewModelGetsCorrectColor() {
    let stylingTuples: [ButtonViewModelInfo] = [
      (.light, .standard, .normal),
      (.light, .wide, .normal),
      (.light, .icon, .normal),

      (.light, .standard, .pressed),
      (.light, .wide, .pressed),
      (.light, .icon, .pressed),

      (.light, .standard, .disabled),
      (.light, .wide, .disabled),
      (.light, .icon, .disabled),

      (.dark, .standard, .normal),
      (.dark, .wide, .normal),
      (.dark, .icon, .normal),

      (.dark, .standard, .pressed),
      (.dark, .wide, .pressed),
      (.dark, .icon, .pressed),

      (.dark, .standard, .disabled),
      (.dark, .wide, .disabled),
      (.dark, .icon, .disabled),
    ]

    for styleTuple in stylingTuples {
      buttonViewModelAndColor(
        scheme: styleTuple.scheme,
        style: styleTuple.style,
        state: styleTuple.state
      ) { viewModel, colors in
        XCTAssertEqual(
          viewModel.buttonStyle.colors.foregroundColor,
          colors.foregroundColor
        )
        XCTAssertEqual(
          viewModel.buttonStyle.colors.backgroundColor,
          colors.backgroundColor
        )
        XCTAssertEqual(
          viewModel.buttonStyle.colors.iconColor,
          colors.iconColor
        )
        XCTAssertEqual(
          viewModel.buttonStyle.colors.iconBorderColor,
          colors.iconBorderColor
        )
      }
    }
  }
}

@available(iOS 13.0, macOS 10.15, *)
extension GoogleSignInButtonStylingTests {
  func buttonViewModelAndColor(
    scheme: GoogleSignInButtonColorScheme,
    style: GoogleSignInButtonStyle,
    state: GoogleSignInButtonState,
    completion: (GoogleSignInButtonViewModel, SignInButtonColor) -> Void
  ) {
    let vm = GoogleSignInButtonViewModel(
      scheme: scheme,
      style: style,
      state: state
    )
    let bc = SignInButtonColor(scheme: scheme, state: state)
    completion(vm, bc)
  }
}
