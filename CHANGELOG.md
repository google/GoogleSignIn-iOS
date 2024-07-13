# 8.0.0
- General release adding Firebase App Check support to establish your
application's integrity while signing in with Google
- Update minimum iOS support to iOS 12 ([#445](https://github.com/google/GoogleSignIn-iOS/pull/445))
- Internal
  - Update AppCheckCore dependency to v11.0 ([#454](https://github.com/google/GoogleSignIn-iOS/pull/454))
  - Add instancetype return to test helper ([#393](https://github.com/google/GoogleSignIn-iOS/pull/393))
  - Remove GTMSessionFetcher modular import ([#403](https://github.com/google/GoogleSignIn-iOS/pull/403))
  - Bump activesupport from 5.2.5 to 5.2.8.1 in the bundler group ([#429](https://github.com/google/GoogleSignIn-iOS/pull/429))
  - Remove deprecated macos-11 runner ([#447](https://github.com/google/GoogleSignIn-iOS/pull/447))
  - Update deprecated archiving API usage in tests ([#449](https://github.com/google/GoogleSignIn-iOS/pull/449))

# 7.1.0-fac-beta-1.1.0
- Beta release supporting Firebase App Check tokens used
to establish your application's integrity while signing in with Google
- Adds privacy manifest support released in [v7.1.0](https://github.com/google/GoogleSignIn-iOS/releases/tag/7.1.0)
- Internal
  - Check integration test for presubmit instruction ([#368](https://github.com/google/GoogleSignIn-iOS/pull/368))
  - Test skip integration key ([#374](https://github.com/google/GoogleSignIn-iOS/pull/374))
  - Add Privacy Manifest to App Check Release Branch ([#392](https://github.com/google/GoogleSignIn-iOS/pull/392))
  - [Add return type to init in GIDFakeFetcherService header](https://github.com/google/GoogleSignIn-iOS/commit/ebf681cac127497da55c932cb5bbf185971a29e7)

# 7.1.0
- Update to Swift 5.0 in `GoogleSignInSwiftSupport` pod ([#317](https://github.com/google/GoogleSignIn-iOS/pull/317))
- Documentation updates ([#351](https://github.com/google/GoogleSignIn-iOS/pull/351), [#372](https://github.com/google/GoogleSignIn-iOS/pull/372))
- Add Privacy Manifest ([#382](https://github.com/google/GoogleSignIn-iOS/pull/382))
- Internal
  - Fix typo in `SFSafariViewController` ([#291](https://github.com/google/GoogleSignIn-iOS/pull/291))
  - Fix `OCMock` usage in unit test ([#298](https://github.com/google/GoogleSignIn-iOS/pull/298))
  - Use new [delegate protocol](https://github.com/google/GTMAppAuth/pull/224) from GTMAppAuth 4.0.0 ([#299](https://github.com/google/GoogleSignIn-iOS/pull/299))
  - Ensure that `completion` is not nil before calling `-[GIDSignIn restorePreviousSignIn:]` ([#301](https://github.com/google/GoogleSignIn-iOS/pull/301))
  - Removes `macos-11` runner in GitHub workflows ([#302](https://github.com/google/GoogleSignIn-iOS/pull/302))
  - Updates button name reference so UI automation tests pass ([#308](https://github.com/google/GoogleSignIn-iOS/pull/308))

# 7.1.0-fac-beta-1.0.0
- Beta release supporting Firebase App Check tokens used
to establish your application's integrity while signing in with Google
- Internal
  - Update SignInSample Podfile minimum iOS version ([#355](https://github.com/google/GoogleSignIn-iOS/pull/355))
  - Update AppCheckExample unit test target to pass during continuous integration ([#356](https://github.com/google/GoogleSignIn-iOS/pull/356))

# 7.1.0-fac-eap-1.0.0
- Early Access Program (EAP) release supporting Firebase App Check tokens used
to establish your application's integrity while signing in with Google
  - Use [`-[GIDSignIn configureWithCompletion:]`](https://github.com/google/GoogleSignIn-iOS/blob/7.1.0-fac-eap-1.0.0/GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h#L79)
    to configure GSI to use Firebase App Check as early as possible in your app
    to minimize latency.
  - Use [`-[GIDSignIn configureDebugProviderWithAPIKey:completion:]`](https://github.com/google/GoogleSignIn-iOS/blob/7.1.0-fac-eap-1.0.0/GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h#L91)
    in debug builds or continuous integration environments.
  - New [sample app](https://github.com/google/GoogleSignIn-iOS/tree/7.1.0-fac-eap-1.0.0/Samples/Swift/AppAttestExample)
    showing example of configuring GSI to use Firebase App Check.
- Internal
  - Fix typo in `SFSafariViewController` ([#291](https://github.com/google/GoogleSignIn-iOS/pull/291))
  - Removes `macos-11` runner in GitHub workflows ([#302](https://github.com/google/GoogleSignIn-iOS/pull/302))
  - Updates button name reference so UI automation tests pass ([#308](https://github.com/google/GoogleSignIn-iOS/pull/308))
  - Ensure that `completion` is not nil before calling
    `-[GIDSignIn restorePreviousSignIn:]` ([#301](https://github.com/google/GoogleSignIn-iOS/pull/301))
  - Use new [delegate protocol](https://github.com/google/GTMAppAuth/pull/224)
    from GTMAppAuth 4.0.0 ([#299](https://github.com/google/GoogleSignIn-iOS/pull/299))

# 7.0.0
- All configuration can now be provided via your `Info.plist` file. ([#228](https://github.com/google/GoogleSignIn-iOS/pull/228))
  - Use the following keys in `<key>KEY</key><string>VALUE</string>` pairs to configure the SDK:
    - `GIDClientID` (required)
    - `GIDServerClientID` (optional)
    - `GIDHostedDomain` (optional)
    - `GIDOpenIDRealm` (optional)
- Support for [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html). ([#187](https://github.com/google/GoogleSignIn-iOS/pull/187))
- API surface improvements ([#249](https://github.com/google/GoogleSignIn-iOS/pull/249), [#228](https://github.com/google/GoogleSignIn-iOS/pull/228), [#187](https://github.com/google/GoogleSignIn-iOS/pull/187))
  - `GIDSignIn`
    - New `configuration` property.
    - Removed `Configuration:` arguments from `signIn:` methods.
    - Removed `addScopes:` and added it to `GIDGoogleUser`.
    - Renamed `callback:` arguments to `completion:` for asynchronous methods taking blocks.
  - `GIDGoogleUser`
    - New `configuration` property.
    - New `addScopes:` method moved from `GIDSignIn`.
    - Removed `authentication` property and replaced it with:
      - New `accessToken` property.
      - New `refreshToken` property.
      - New `idToken` property.
      - New `fetcherAuthorizer` property.
      - New `refreshTokensIfNeededWithCompletion:` method.
  - New `GIDToken` class to represent access, refresh, and ID tokens in `GIDGoogleUser`.
  - New `GIDSignInResult` class to represent the result of a successful signIn or addScopes flow.
  - Removed `GIDSignInCallback`, `GIDDisconnectCallback`, and `GIDAuthenticationAction` block type definitions.

# 6.2.4
- Updated the GTMSessionFetcher dependency to allow 2.x versions. ([#207](https://github.com/google/GoogleSignIn-iOS/pull/207))

# 6.2.3
- Fix resource loading in GoogleSignInSwift with CocoaPods use_frameworks! ([#197](https://github.com/google/GoogleSignIn-iOS/pull/197))
- Prevent build errors for GoogleSignInSwift in certain scenarios when using Swift Package Manager. ([#166](https://github.com/google/GoogleSignIn-iOS/pull/166))

# 6.2.2
- Prevent build errors for GoogleSignInSwift when using Swift Package Manager. ([#157](https://github.com/google/GoogleSignIn-iOS/pull/157))
- Prevent a build error on Xcode 12 and earlier. ([#158](https://github.com/google/GoogleSignIn-iOS/pull/158))

# 6.2.1
- Use `GoogleSignInSwiftSupport` as the name of the Swift support CocoaPod. ([#137](https://github.com/google/GoogleSignIn-iOS/pull/137))

# 6.2.0
- Support for macOS. ([#104](https://github.com/google/GoogleSignIn-iOS/pull/104))
- Added a SwiftUI "Sign in with Google" button. ([#103](https://github.com/google/GoogleSignIn-iOS/pull/103))
- Added the ability to request additional scopes at sign-in time. ([#30](https://github.com/google/GoogleSignIn-iOS/pull/30))
- Fixed several issues. ([#87](https://github.com/google/GoogleSignIn-iOS/pull/87), [#106](https://github.com/google/GoogleSignIn-iOS/issues/106))

# 6.1.0
- New Swift sample app demonstrating SwiftUI.
  ([#63](https://github.com/google/GoogleSignIn-iOS/pull/63))
- Support for Mac Catalyst.
- Improvements to the `addScopes` implementation.
  ([#68](https://github.com/google/GoogleSignIn-iOS/pull/68),
  [#70](https://github.com/google/GoogleSignIn-iOS/pull/70))

# 6.0.2
- Ensure that module imports can be used when built as a library.
  ([#53](https://github.com/google/GoogleSignIn-iOS/pull/53))

# 6.0.1
- Fixes nested callbacks not being called for signIn and addScopes methods.
  ([#29](https://github.com/google/GoogleSignIn-iOS/pull/29))

# 6.0.0
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

# 5.0.2
- Fixes the wrong error code being sent to `signIn:didSignInForUser:withError:` when the user
  cancels iOS's consent dialog during the sign-in flow.

# 5.0.1
- Fixes an issue that the sign in flow cannot be correctly started on iOS 13.
- The zip distribution requires Xcode 11 or above.

# 5.0.0
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

# 4.4.0
- Removes the dependency on GTM OAuth 2.

# 4.3.0
- Supports Google's Enterprise Mobile Management.

# 4.2.0
- Adds `grantedScopes` to `GIDGoogleUser`, allowing confirmation of which scopes
  have been granted after a successful sign-in.
- Deprecates `accessibleScopes` in `GIDGoogleUser`, use `grantedScopes` instead.
- Localizes `GIDSignInButton` for hi (Hindi) and fr-CA (French (Canada)).
- Adds dependency to the system `LocalAuthentication` framework.

# 4.1.2
- Add `pod try` support for the GoogleSignIn CocoaPod.

# 4.1.1
- Fixes an issue that `GIDSignInUIDelegate`'s `signInWillDispatch:error:` was
  not called on iOS 11. Please note that it is intended that neither
  `signIn:presentViewController:` nor `signIn:dismissViewController:` is called
  on iOS 11 because SFAuthenticationSession is not presented by the app's view
  controller.

# 4.1.0
- Uses SFAuthenticationSession on iOS 11.

# 4.0.2
- No longer depends on GoogleAppUtilities.

# 4.0.1
- Switches to open source pod dependencies.
- Appearance of sign-in button no longer depends on requested scopes.

# 4.0.0
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

# 3.0.0
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

# 2.4.0
- Updates sign-in button with the new Google logo.
- Supports domain restriction for sign-in.
- Allows refreshing ID tokens.

# 2.3.2
- No longer requires Xcode 7.

# 2.3.1
- Fixes a crash in `GIDProfileData`'s `imageURLWithDimension:`.

# 2.3.0
- Requires Xcode 7.0 or above.
- Uses SFSafariViewController for signing in on iOS 9.  `uiDelegate` must be
  set for this to work.
- Optimizes fetching user profile.
- Supports GTMFetcherAuthorizationProtocol in GIDAuthentication.

# 2.2.0
- Compatible with iOS 9 (beta).  Note that this version of the Sign-In SDK does
  not include bitcode, so you must set ENABLE_BITCODE to NO in your project if
  you use Xcode 7.
- Adds descriptive identifiers for GIDSignInButton's Auto Layout constraints.
- `signInSilently` no longer requires setting `uiDelegate`.

# 2.1.0
- Fixes Auto Layout issues with GIDSignInButton.
- Adds API to refresh access token in GIDAuthentication.
- Better exception description for unassigned clientID in GIDSignIn.
- Other minor bug fixes.

# 2.0.1
- Bug fixes

# 2.0.0
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

# 1.0.0
- New sign-in focused SDK with refreshed API
- Dynamically rendered sign-in button with contextual branding
- Basic profile support
- Added allowsSignInWithBrowser property
