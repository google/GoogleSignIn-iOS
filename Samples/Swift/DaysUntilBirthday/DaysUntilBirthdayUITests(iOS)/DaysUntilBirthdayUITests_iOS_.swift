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

class DaysUntilBirthdayUITests_iOS_: XCTestCase {
  private let signInStaticText =
    "“DaysUntilBirthday(iOS)” Wants to Use “google.com” to Sign In"
  private let timeout: TimeInterval = 5

  private let sampleApp = XCUIApplication()
  private let springboardApp = XCUIApplication(
    bundleIdentifier: "com.apple.springboard"
  )

  func testSignInNavigateToDaysUntilBirthdayAndDisconnect() {
    sampleApp.launch()

    XCTAssertTrue(signIn())
    XCTAssertTrue(navigateToDaysUntilBirthday())
    XCTAssertTrue(navigateBackToUserProfileView())

    // Disconnect so the next test run works as if it is the first time
    sampleApp.navigationBars.buttons["Disconnect"].tap()

    guard sampleApp
            .buttons["GoogleSignInButton"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Disconnecting should return user to sign in view")
    }
  }

  func testSignInAndSignOut() {
    sampleApp.launch()
    XCTAssertTrue(signIn())

    guard sampleApp
            .navigationBars
            .buttons["Sign Out"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find the 'Disconnect' button")
    }
    sampleApp.buttons["Sign Out"].tap()

    guard sampleApp
            .buttons["GoogleSignInButton"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Signing out should return user to sign in view")
    }
  }
}

extension DaysUntilBirthdayUITests_iOS_ {
  /// Performs a sign in.
  /// - returns: `true` if the sign in was succesfull.
  func signIn() -> Bool {
    let signInButton = sampleApp.buttons["GoogleSignInButton"]
    guard signInButton.exists else {
      XCTFail("Sign in button does not exist")
      return false
    }
    signInButton.tap()

    guard springboardApp
            .staticTexts[signInStaticText]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to display permission prompt")
      return false
    }

    guard springboardApp
            .buttons["Continue"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to find 'Continue' button")
      return false
    }
    springboardApp.buttons["Continue"].tap()

    if sampleApp
        .staticTexts[Credential.email.rawValue]
        .waitForExistence(timeout: timeout) {
      // This email was previously used to sign in
      XCTAssertTrue(useExistingSignIn())
    } else {
      // This is a first time sign in
      XCTAssertTrue(signInForTheFirstTime())
    }

    guard sampleApp.wait(for: .runningForeground, timeout: timeout) else {
      XCTFail("Failed to return sample app to foreground")
      return false
    }
    guard sampleApp.staticTexts["User Profile"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to sign in and return to app's User Profile view.")
      return false
    }

    return true
  }

  /// Signs in expecting the first time flow.
  /// @discussion
  /// This will assumme the full flow where a user must type in an email and
  /// password to sign in with.
  func signInForTheFirstTime() -> Bool {
    guard sampleApp.textFields["Email or phone"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to find email textfield")
      return false
    }
    guard sampleApp
            .keyboards
            .element
            .buttons["return"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to find 'return' button")
      return false
    }

    sampleApp.textFields["Email or phone"].typeText(Credential.email.rawValue)
    sampleApp.keyboards.element.buttons["return"].tap()

    guard sampleApp.secureTextFields["Enter your password"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to find password textfield")
      return false
    }
    guard sampleApp
            .keyboards
            .element
            .buttons["go"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to find 'go' button")
      return false
    }

    sampleApp
      .secureTextFields["Enter your password"]
      .typeText(Credential.password.rawValue)
    sampleApp.keyboards.element.buttons["go"].tap()

    return true
  }

  /// Signs in expecting a prior sign in.
  /// @discussion
  /// This will assume that there is a `Credential.email` in a list to select
  /// and sign in with.
  func useExistingSignIn() -> Bool {
    guard sampleApp.staticTexts[Credential.email.rawValue].exists else {
      XCTFail("Email used for previous sign-in not in list")
      return false
    }
    guard sampleApp.staticTexts[Credential.email.rawValue].isHittable else {
      XCTFail("Email used for previous sign-in not tappable")
      return false
    }
    sampleApp.staticTexts[Credential.email.rawValue].tap()

    return true
  }

  /// Navigates to the days until birthday view from the user profile view.
  /// - returns: `true` if the navigation was performed successfully.
  /// - note: If `firstSignIn` is `true`, then we should expect a pop up asking
  /// for permission.
  func navigateToDaysUntilBirthday() -> Bool {
    guard sampleApp.buttons["View Days Until Birthday"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to find button navigating to days until birthday view")
      return false
    }
    sampleApp.buttons["View Days Until Birthday"].tap()

    if springboardApp
        .staticTexts[signInStaticText]
        .waitForExistence(timeout: timeout) {
      guard springboardApp
              .buttons["Continue"]
              .waitForExistence(timeout: timeout) else {
        XCTFail("Failed to find 'Continue' button")
        return false
      }
      springboardApp.buttons["Continue"].tap()

      guard sampleApp
              .staticTexts["Days Until Birthday wants to access your Google Account"]
              .waitForExistence(timeout: timeout) else {
        XCTFail("Failed to find permission screen")
        return false
      }
      guard sampleApp.buttons["Allow"].waitForExistence(timeout: timeout) else {
        XCTFail("Failed to find 'Allow' button")
        return false
      }
      sampleApp.buttons["Allow"].tap()
    }

    guard sampleApp.staticTexts["Days Until Birthday"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to show days until birthday view")
      return false
    }

    return true
  }

  /// Navigates back to the User Profile view from the Days Until Birthday View.
  /// - returns: `true` if the navigation was successfully performed.
  func navigateBackToUserProfileView() -> Bool {
    guard sampleApp
            .navigationBars
            .buttons["User Profile"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to show navigation button back to user profile view")
      return false
    }
    sampleApp.navigationBars.buttons["User Profile"].tap()

    guard sampleApp
            .navigationBars
            .buttons["Disconnect"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to find the 'Disconnect' button")
      return false
    }

    return true
  }
}
