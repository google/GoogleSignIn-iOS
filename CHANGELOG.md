# 6.1.0 (2021-12-16)
- New Swift sample app demonstrating SwiftUI.
  ([#63](https://github.com/google/GoogleSignIn-iOS/pull/63))
- Support for Mac Catalyst.
- Improvements to the `addScopes` implementation.
  ([#68](https://github.com/google/GoogleSignIn-iOS/pull/68),
  [#70](https://github.com/google/GoogleSignIn-iOS/pull/70))

# 6.0.2 (2021-8-20)
- Ensure that module imports can be used when built as a library.
  ([#53](https://github.com/google/GoogleSignIn-iOS/pull/53))

# 6.0.1 (2021-7-21)
- Fixes nested callbacks not being called for signIn and addScopes methods.
  ([#29](https://github.com/google/GoogleSignIn-iOS/pull/29))

# 6.0.0 (2021-7-13)
- Google Sign-In for iOS is now open source.
- Swift Package Manager support.
- Support for Simulator on M1 Macs.
- API surface updates
  - `GIDSignIn`
    - `sharedInstance` is now a class property.
    - `signIn` is now `signInWithConfiguration:presentingViewController:callback:` and always
      requests basic profile scopes.
    - `addScopes:presentingViewController:callback:` is the new way to add scopes beyond basic
      profile to a currently signed-in user.
    - `restorePreviousSignIn` is now `restorePreviousSignInWithCallback:`.
    - `disconnect` is now `disconnectWithCallback:`.
    - The `GIDSignInDelegate` protocol has been removed in favor of `GIDSignInCallback` and
      `GIDDisconnectCallback` blocks.
    - All sign-in flow configuration properties have been moved to `GIDConfiguration`.
  - The `GIDConfiguration` class had been added to represent the configuration needed to sign in a
    user.
  - `GIDAuthentication`
    - `getTokensWithHandler:` is now `doWithFreshTokens:`.
    - The `GIDAuthenticationHandler` typedef has been renamed `GIDAuthenticationAction`.
    - `refreshTokensWithHandler:` has been removed, use `doWithFreshTokens:` instead.
  - `GIDSignInButton` no longer makes calls to `GIDSignIn` internally and will need to be wired to
    an `IBAction` or similar in order for you to call
    `signInWithConfiguration:presentingViewController:callback:` to initiate a sign-in flow.

# 5.0.2 (2019-11-7)
- Fixes the wrong error code being sent to `signIn:didSignInForUser:withError:` when the user
  cancels iOS's consent dialog during the sign-in flow.

# 5.0.1 (2019-10-9)
- Fixes an issue that the sign in flow cannot be correctly started on iOS 13.
- The zip distribution requires Xcode 11 or above.

# 5.0.0 (2019-8-14)
- Changes to GIDSignIn
  - `uiDelegate` has been replaced with `presentingViewController`.
  - `hasAuthInKeychain` has been replaced with `hasPreviousSignIn`.
  - `signInSilently` has been replaced with `restorePreviousSignIn`.
  - Removed deprecated `kGIDSignInErrorCodeNoSignInHandlersInstalled` error code.
- Changes to GIDAuthentication
  - Removed deprecated methods `getAccessTokenWithHandler:` and `refreshAccessTokenWithHandler:`.
- Changes to GIDGoogleUser
  - Removed deprecated property `accessibleScopes`, use `grantedScopes` instead.
- Adds dependencies on AppAuth and GTMAppAuth.
- Removes the dependency on GoogleToolboxForMac.
- Drops support for iOS 7.

# 4.4.0 (2018-11-26)
- Removes the dependency on GTM OAuth 2.

# 4.3.0 (2018-10-1)
- Supports Google's Enterprise Mobile Management.

# 4.2.0 (2018-8-10)
- Adds `grantedScopes` to `GIDGoogleUser`, allowing confirmation of which scopes
  have been granted after a successful sign-in.
- Deprecates `accessibleScopes` in `GIDGoogleUser`, use `grantedScopes` instead.
- Localizes `GIDSignInButton` for hi (Hindi) and fr-CA (French (Canada)).
- Adds dependency to the system `LocalAuthentication` framework.

# 4.1.2 (2018-1-8)
- Add `pod try` support for the GoogleSignIn CocoaPod.

# 4.1.1 (2017-10-17)
- Fixes an issue that `GIDSignInUIDelegate`'s `signInWillDispatch:error:` was
  not called on iOS 11. Please note that it is intended that neither
  `signIn:presentViewController:` nor `signIn:dismissViewController:` is called
  on iOS 11 because SFAuthenticationSession is not presented by the app's view
  controller.

# 4.1.0 (2017-09-13)
- Uses SFAuthenticationSession on iOS 11.

# 4.0.2 (2017-2-6)
- No longer depends on GoogleAppUtilities.

# 4.0.1 (2016-10-24)
- Switches to open source pod dependencies.
- Appearance of sign-in button no longer depends on requested scopes.

# 4.0.0 (2016-4-21)
- GoogleSignIn pod now takes form of a static framework. Import with
  `#import <GoogleSignIn/GoogleSignIn.h>` in Objective-C.
- Adds module support. You can also use `@import GoogleSignIn;` in Objective-C,
  if module is enabled, and `import GoogleSignIn` in Swift without using a
  bridge-header.
- For users of the stand-alone zip distribution, multiple frameworks are now
  provided and all need to be added to a project. This decomposition allows more
  flexibility in case of duplicated dependencies.
- Removes deprecated method `checkGoogleSignInAppInstalled` from `GIDSignIn`.
- Removes `allowsSignInWithBrowser` and `allowsSignInWithWebView` properties
  from `GIDSignIn`.
- No longer requires adding bundle ID as a URL scheme supported by the app.

# 3.0.0 (2016-3-4)
- Provides `givenName` and `familyName` properties on `GIDProfileData`.
- Allows setting the `loginHint` property on `GIDSignIn` to prefill the user's
  ID or email address in the sign-in flow.
- Removed the `UIViewController(SignIn)` category as well as the `delegate`
  property from `GIDSignInButton`.
- Requires that `uiDelegate` has been set properly on `GIDSignIn` and that
  SafariServices framework has been linked.
- Removes the dependency on StoreKit.
- Provides bitcode support.
- Requires Xcode 7.0 or above due to bitcode incompatibilities with Xcode 6.

# 2.4.0 (2015-10-26)
- Updates sign-in button with the new Google logo.
- Supports domain restriction for sign-in.
- Allows refreshing ID tokens.

# 2.3.2 (2015-10-9)
- No longer requires Xcode 7.

# 2.3.1 (2015-10-1)
- Fixes a crash in `GIDProfileData`'s `imageURLWithDimension:`.

# 2.3.0 (2015-9-25)
- Requires Xcode 7.0 or above.
- Uses SFSafariViewController for signing in on iOS 9.  `uiDelegate` must be
  set for this to work.
- Optimizes fetching user profile.
- Supports GTMFetcherAuthorizationProtocol in GIDAuthentication.

# 2.2.0 (2015-7-15)
- Compatible with iOS 9 (beta).  Note that this version of the Sign-In SDK does
  not include bitcode, so you must set ENABLE_BITCODE to NO in your project if
  you use Xcode 7.
- Adds descriptive identifiers for GIDSignInButton's Auto Layout constraints.
- `signInSilently` no longer requires setting `uiDelegate`.

# 2.1.0 (2015-6-17)
- Fixes Auto Layout issues with GIDSignInButton.
- Adds API to refresh access token in GIDAuthentication.
- Better exception description for unassigned clientID in GIDSignIn.
- Other minor bug fixes.

# 2.0.1 (2015-5-28)
- Bug fixes

# 2.0.0 (2015-5-21)
- Supports sign-in via UIWebView rather than app switching to a browser,
  configurable with the new `allowsSignInWithWebView` property.
- Now apps which have disabled the app switch to a browser via the
  `allowsSignInWithBrowser` and in-app web view via `allowsSignInWithWebView`
  properties have the option to display a prompt instructing the user to
  download the Google app from the App Store.
- Fixes sign-in button sizing issue when auto-layout is enabled
- `signInSilently` now calls the delegate with error when `hasAuthInKeychain`
  is `NO` as documented
- Other minor bug fixes

# 1.0.0 (2015-3-12)
- New sign-in focused SDK with refreshed API
- Dynamically rendered sign-in button with contextual branding
- Basic profile support
- Added allowsSignInWithBrowser property
