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

  func testSwiftUIButtonTapStartsFlowForFirstSignIn() {
    sampleApp.launch()
    let signInButton = sampleApp.buttons["GoogleSignInButton"]
    XCTAssertTrue(signInButton.exists)
    signInButton.tap()

    guard springboardApp
            .staticTexts[signInStaticText]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to display prompt")
    }

    guard springboardApp
            .buttons["Continue"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find 'Continue' button")
    }

    springboardApp.buttons["Continue"].tap()
    guard sampleApp.textFields["Email or phone"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find email textfield")
    }
    guard sampleApp
            .keyboards
            .element
            .buttons["return"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find 'Next' button")
    }

    sampleApp.textFields["Email or phone"].typeText(Credential.email.rawValue)
    sampleApp.keyboards.element.buttons["return"].tap()

    guard sampleApp.secureTextFields["Enter your password"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find password textfield")
    }
    guard sampleApp
            .keyboards
            .element
            .buttons["go"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find 'Next' button")
    }

    sampleApp
      .secureTextFields["Enter your password"]
      .typeText(Credential.password.rawValue)
    sampleApp.keyboards.element.buttons["go"].tap()

    guard sampleApp.wait(for: .runningForeground, timeout: timeout) else {
      return XCTFail("Failed to return sample app to foreground")
    }
    guard sampleApp.staticTexts["User Profile"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to sign in and return to app's User Profile view.")
    }

    guard sampleApp.buttons["View Days Until Birthday"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find button revealing days until birthday")
    }
    sampleApp.buttons["View Days Until Birthday"].tap()

    guard springboardApp
            .staticTexts[signInStaticText]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to display prompt")
    }

    guard springboardApp
            .buttons["Continue"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find 'Continue' button")
    }
    springboardApp.buttons["Continue"].tap()

    guard sampleApp
            .staticTexts["Days Until Birthday wants to access your Google Account"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find permission screen")
    }
    guard sampleApp.buttons["Allow"].waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to find 'Allow' button")
    }
    sampleApp.buttons["Allow"].tap()

    guard sampleApp.staticTexts["Days Until Birthday"]
            .waitForExistence(timeout: timeout) else {
      return XCTFail("Failed to return to view showing days until birthday")
    }
  }
}
