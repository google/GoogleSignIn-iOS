[![Release](https://img.shields.io/github/v/release/google/GoogleSignIn-iOS?style=flat)](https://github.com/google/GoogleSignIn-iOS/releases)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-brightgreen?style=flat)](https://swift.org/package-manager/)
[![License](https://img.shields.io/github/license/google/GoogleSignIn-iOS?style=flat)](LICENSE)
[![unit_tests](https://github.com/google/GoogleSignIn-iOS/actions/workflows/unit_tests.yml/badge.svg?branch=main)](https://github.com/google/GoogleSignIn-iOS/actions/workflows/unit_tests.yml)
[![integration_tests](https://github.com/google/GoogleSignIn-iOS/actions/workflows/integration_tests.yml/badge.svg?branch=main)](https://github.com/google/GoogleSignIn-iOS/actions/workflows/integration_tests.yml)

> [!IMPORTANT]
> **CocoaPods distribution is deprecated.** CocoaPods trunk becomes read-only on December 2, 2026, and future Google Sign-In releases will be distributed through Swift Package Manager only. See [Migrating from CocoaPods to Swift Package Manager](MIGRATING_FROM_COCOAPODS.md).

# Google Sign-In for iOS and macOS

Get users into your apps quickly and securely, using a registration system they
already use and trust—their Google account.

Visit [our developer site](https://developers.google.com/identity/sign-in/ios/)
for integration instructions, documentation, support information, and terms of
service.

## Installation

Google Sign-In is distributed with [Swift Package Manager](https://swift.org/package-manager/).

In Xcode, choose **File > Add Package Dependencies…**, enter
`https://github.com/google/GoogleSignIn-iOS`, and add the product you need to your target:

* `GoogleSignIn` — the core SDK (Swift and Objective-C).
* `GoogleSignInSwift` — the SwiftUI `GoogleSignInButton`.

Or add it to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "10.0.0")
]
```

and depend on `.product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")` (and, for SwiftUI,
`.product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")`) in your target.

If you currently use CocoaPods, see
[Migrating from CocoaPods to Swift Package Manager](MIGRATING_FROM_COCOAPODS.md).

## Getting Started

Try either the [Objective-C](Samples/ObjC) or [Swift](Samples/Swift) sample app.
For example, to demo the Objective-C sample project:

```
git clone https://github.com/google/GoogleSignIn-iOS
open GoogleSignIn-iOS/Samples/ObjC/SignInSample/SignInSample.xcodeproj
```

If you would like to see a Swift example, take a look at 
[Samples/Swift/DaysUntilBirthday](Samples/Swift/DaysUntilBirthday).

* Add Google Sign-In to your own app by following our
[getting started guides](https://developers.google.com/identity/sign-in/ios/start-integrating).
* Take a look at the
[API reference](https://developers.google.com/identity/sign-in/ios/api/).

## Google Sign-In on macOS

Google Sign-In allows your users to sign-in to your native macOS app using their Google account
and default browser.  When building for macOS, the `signInWithConfiguration:` and `addScopes:`
methods take a `presentingWindow:` parameter in place of `presentingViewController:`.  Note that
in order for your macOS app to store credentials via the Keychain on macOS, you will need to add
`$(AppIdentifierPrefix)$(CFBundleIdentifier)` as the first item in its keychain access group.

### Mac Catalyst

Google Sign-In also supports iOS apps that are built for macOS via
[Mac Catalyst](https://developer.apple.com/mac-catalyst/).  In order for your Mac Catalyst app
to store credentials via the Keychain on macOS, you will need to add
`$(AppIdentifierPrefix)$(CFBundleIdentifier)` as the first item in the keychain
access group.

## Using the Google Sign-In Button

There are several ways to add a 'Sign in with Google' button to your app, which
path you choose will depend on your UI framework and target platform.

### SwiftUI (iOS and macOS)

Creating a 'Sign in with Google' button in SwiftUI can be as simple as this:

```
GoogleSignInButton {
  GIDSignIn.sharedInstance.signIn(withPresenting: yourViewController) { signInResult, error in
      // check `error`; do something with `signInResult`
  }
}
```

This example takes advantage of the initializer's [default argument for the
view model](GoogleSignInSwift/Sources/GoogleSignInButton.swift#L39).
The default arguments for the view model will use the light scheme, the
standard button style, and the normal button state.
You can supply an instance of [`GoogleSignInButtonViewModel`](GoogleSignInSwift/Sources/GoogleSignInButtonViewModel.swift)
with different values for these properties to customize the button.
[This convenience initializer](GoogleSignInSwift/Sources/GoogleSignInButton.swift#L56) 
provides parameters that you can use to set these values as needed.

### UIKit (iOS)

If you are not using SwiftUI to build your user interfaces, you can either
create `GIDSignInButton` programmatically, or in a Xib/Storyboard. 
If you are writing programmatic UI code, it will look something like this:

`let button = GIDSignInButton(frame: CGRect(<YOUR_RECT>))`

### AppKit (macOS)

Given that `GIDSignInButton` is implemented as a subclass of `UIControl`, it
will not be available on macOS. 
You can instead use the SwiftUI Google sign-in button.
Doing so will require that you wrap the SwiftUI button in a hosting view so
that it will be available for use in AppKit.

```
let signInButton = GoogleSignInButton {
  GIDSignIn.sharedInstance.signIn(withPresenting: yourViewController) { signInResult, error in
      // check `error`; do something with `signInResult`
  }
}
let hostedButton = NSHostingView(rootView: signInButton)
```

## A Note on iOS Keychain Access Groups

GSI uses your default (first listed) keychain access group. If you don't add a
custom keychain access group, the default keychain access group is provided by
Xcode and looks like `$(AppIdentifierPrefix)$(CFBundleIdentifier)`.

GSI [removes keychain items upon fresh install](https://github.com/google/GoogleSignIn-iOS/pull/567)
to ensure that stale credentials from previous installs of your app are not
mistakenly used. If your app uses a shared access group by default this may
lead to new installs of apps sharing the same keychain access group to remove
keychain credentials for apps already installed. 

To prevent unintentional credential removal, you can explicitly list the
typical default access group (or whatever you prefer so long as it is not
shared) in your list first. GSI, will then use that default access group.
