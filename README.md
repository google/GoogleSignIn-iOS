[![Version](https://img.shields.io/cocoapods/v/GoogleSignIn.svg?style=flat)](https://cocoapods.org/pods/GoogleSignIn)
[![Platform](https://img.shields.io/cocoapods/p/GoogleSignIn.svg?style=flat)](https://cocoapods.org/pods/GoogleSignIn)
[![License](https://img.shields.io/cocoapods/l/GoogleSignIn.svg?style=flat)](https://cocoapods.org/pods/GoogleSignIn)
[![tests](https://github.com/google/GoogleSignIn-iOS/actions/workflows/tests.yml/badge.svg?event=push)](https://github.com/google/GoogleSignIn-iOS/actions/workflows/tests.yml)

# Google Sign-In for iOS and macOS

Get users into your apps quickly and securely, using a registration system they
already use and trust—their Google account.

Visit [our developer site](https://developers.google.com/identity/sign-in/ios/)
for integration instructions, documentation, support information, and terms of
service.

## Getting Started

Try either the [Objective-C](Samples/ObjC) or [Swift](Samples/Swift) sample app.
For example, to demo the Objective-C sample project, you have three options:

1. Using [CocoaPods](https://cocoapods.org/)'s `try` method:

```
pod try GoogleSignIn
```

Note, this will default to providing you with the Objective-C sample app.

2. Using CocoaPod's `install` method:

```
git clone https://github.com/google/GoogleSignIn-iOS
cd GoogleSignIn-iOS/Samples/ObjC/SignInSample/
pod install
open SignInSampleForPod.xcworkspace
```

3. Using [Swift Package Manager](https://swift.org/package-manager/):

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
in order for your macOS app to store credientials via the Keychain on macOS, you will need to
[sign your app](https://developer.apple.com/support/code-signing/).

### Mac Catalyst

Google Sign-In also supports iOS apps that are built for macOS via
[Mac Catalyst](https://developer.apple.com/mac-catalyst/).  In order for your Mac Catalyst app
to store credientials via the Keychain on macOS, you will need to
[sign your app](https://developer.apple.com/support/code-signing/).
