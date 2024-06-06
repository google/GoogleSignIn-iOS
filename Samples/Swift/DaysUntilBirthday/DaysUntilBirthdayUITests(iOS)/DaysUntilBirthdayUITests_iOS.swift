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

class DaysUntilBirthdayUITests_iOS: XCTestCase {
  private let signInStaticText =
    "“DaysUntilBirthday (iOS)” Wants to Use “google.com” to Sign In"
  private let passwordManagerPrompt =
    "Would you like to save this password to use with apps and websites?"
  private let signInDisclaimerHeaderText =
    "Sign in to Days Until Birthday"
  private let additionalAccessHeaderText = "Days Until Birthday wants additional access to your Google Account"
  private let appTrustWarningText = "Make sure you trust Days Until Birthday"
  private let chooseAnAccountHeaderText = "Choose an account"
  private let notNowText = "Not Now"
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

extension DaysUntilBirthdayUITests_iOS {
  /// Performs a sign in.
  /// - returns: `true` if the sign in was successful.
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
            .buttons["return"]
            .waitForExistence(timeout: timeout) else {
      XCTFail("Failed to find 'return' button")
      return false
    }

    sampleApp
      .secureTextFields["Enter your password"]
      .typeText(Credential.password.rawValue)
    sampleApp.keyboards.element.buttons["return"].tap()

    if sampleApp
      .staticTexts[passwordManagerPrompt]
      .waitForExistence(timeout: timeout) {
      guard sampleApp
        .buttons[notNowText]
        .waitForExistence(timeout: timeout) else {
        XCTFail("Failed to find \(notNowText) button")
        return false
      }
      sampleApp.buttons[notNowText].tap()
    }

    // Proceed through sign-in disclaimer and/or access request view(s) if needed
    handleSignInDisclaimerIfNeeded()
    handleAccessRequestIfNeeded()

    return true
  }

  /// Signs in expecting a prior sign in.
  /// @discussion
  /// This will check that there is a `Credential.email` in a list to select and
  /// sign in with.
  func useExistingSignIn() -> Bool {
    guard findAndTapExistingSignedInEmail() else {
      XCTFail("Failed to find signed-in account")
      return false
    }

    handleSignInDisclaimerIfNeeded()
    handleAccessRequestIfNeeded()

    return true
  }

  /// Navigates to the days until birthday view from the user profile view.
  /// - returns: `true` if the navigation was performed successfully.
  /// - note: This method will attempt to find a pop up asking for permission to
  /// sign in with Google.
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

      if sampleApp
        .staticTexts[chooseAnAccountHeaderText]
        .waitForExistence(timeout: timeout) {
        guard findAndTapExistingSignedInEmail() else {
          XCTFail("Failed to find signed-in account")
          return false
        }
      }

      handleAccessRequestIfNeeded()
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

  /// Proceeds through the view with header "Days Until Birthday wants additional access to your Google Account" if needed.
  func handleAccessRequestIfNeeded() {
    let currentlyShowingAdditionalAccessRequest = sampleApp.staticTexts[additionalAccessHeaderText]
      .waitForExistence(timeout: timeout) && sampleApp.staticTexts[appTrustWarningText]
      .waitForExistence(timeout: timeout) &&
    sampleApp.buttons["Continue"]
      .waitForExistence(timeout: timeout)

    if currentlyShowingAdditionalAccessRequest {
      sampleApp.buttons["Continue"].tap()
    }
  }

  /// Proceeds through the sign-in disclaimer view if needed.
  func handleSignInDisclaimerIfNeeded() {
    let currentlyShowingSignInDisclaimer = sampleApp.staticTexts[signInDisclaimerHeaderText]
      .waitForExistence(timeout: timeout) &&
    sampleApp.buttons["Continue"]
      .waitForExistence(timeout: timeout)

    if currentlyShowingSignInDisclaimer {
      sampleApp.buttons["Continue"].tap()
    }
  }

  /// This method looks for an account in the current view that reflects an already-signed-in state, and taps it.
  /// - returns: true if the signed-in account was found and tapped, otherwise returns false.
  func findAndTapExistingSignedInEmail() -> Bool {
    guard sampleApp.staticTexts[Credential.email.rawValue].exists else {
      XCTFail("Email used for previous sign-in was not found.")
      return false
    }
    guard sampleApp.staticTexts[Credential.email.rawValue].isHittable else {
      XCTFail("Email used for previous sign-in not tappable.")
      return false
    }
    sampleApp.staticTexts[Credential.email.rawValue].tap()
    return true
  }
}
