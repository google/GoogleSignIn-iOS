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

import Combine

/// A view model for the SwiftUI sign-in button publishing changes for the
/// button scheme, style, and state.
@available(iOS 13.0, macOS 10.15, *)
public class GoogleSignInButtonViewModel: ObservableObject {
  @Published public var scheme: GoogleSignInButtonColorScheme
  @Published public var style: GoogleSignInButtonStyle
  @Published public var state: GoogleSignInButtonState

  /// A computed property providing the button's size, colors, corner radius,
  /// and shadow based on this current view model's `SignInButtonStyle`.
  var buttonStyle: SwiftUIButtonStyle {
    return SwiftUIButtonStyle(style: style, state: state, scheme: scheme)
  }

  /// Creates instances of the SwiftUI sign-in button.
  /// - parameter scheme: An instance of `GoogleSignInButtonColorScheme`. Defaults to
  /// `.light`.
  /// - parameter style: An instance of `GoogleSignInButtonStyle`. Defaults to
  /// `.standard`.
  /// - parameter state: An instance of `GoogleSignInButtonState`. Defaults to
  /// `.normal`.
  @available(iOS 13.0, macOS 10.15, *)
  public init(
    scheme: GoogleSignInButtonColorScheme = .light,
    style: GoogleSignInButtonStyle = .standard,
    state: GoogleSignInButtonState = .normal) {
      self.scheme = scheme
      self.style = style
      self.state = state
  }
}

#endif // !arch(arm) && !arch(i386)
