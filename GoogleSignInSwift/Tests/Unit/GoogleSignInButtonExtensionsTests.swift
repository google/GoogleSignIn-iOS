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
import SwiftUI
@testable import GoogleSignInSwift

@available(iOS 13.0, macOS 10.15, *)
class GoogleSignInButtonExtensionsTests: XCTestCase {

  func testThatBundleExtensionReturnsImageIconURL() {
    let googleIcon = Bundle.urlForGoogleResource(name: googleImageName, withExtension: "png")
    XCTAssertNotNil(googleIcon)
  }

  func testThatBundleExtensionReturnsFontURL() {
    let googleFont = Bundle.urlForGoogleResource(name: fontNameRobotoBold, withExtension: "ttf")
    XCTAssertNotNil(googleFont)
  }

}
