# Migrating from CocoaPods to Swift Package Manager

CocoaPods trunk becomes read-only on December 2, 2026. Google Sign-In <FINAL_POD_VERSION> is the last version published to CocoaPods (both the `GoogleSignIn` and `GoogleSignInSwiftSupport` pods). Existing pod versions remain installable, but future Google Sign-In releases are distributed via Swift Package Manager only.

## Steps

1. In the project directory, remove the `pod 'GoogleSignIn'` and `pod 'GoogleSignInSwiftSupport'` lines from the `Podfile`. If these were the only pods, run `pod deintegrate`, delete the `Podfile`, `Podfile.lock`, and the generated `.xcworkspace`, and open the `.xcodeproj` from then on.
2. In Xcode: **File > Add Package Dependencies…**, enter `https://github.com/google/GoogleSignIn-iOS`, and choose "Up to Next Major Version" from the current version.
3. Add the product(s) matching your old pod(s) to each target (table below).
4. Imports do not change. Clean the build folder and build.

| Podfile entry | SPM product | Swift import | Objective-C import |
| --- | --- | --- | --- |
| `pod 'GoogleSignIn'` | `GoogleSignIn` | `import GoogleSignIn` | `@import GoogleSignIn;` |
| `pod 'GoogleSignInSwiftSupport'` | `GoogleSignInSwift` | `import GoogleSignInSwift` | (Swift only) |

Note: The `GoogleSignInSwiftSupport` pod already built a module named `GoogleSignInSwift`, so existing imports keep working unchanged.

## Resources

Under Swift Package Manager, the SDK's resources ship in a bundle named `GoogleSignIn_GoogleSignIn.bundle` instead of `GoogleSignIn.bundle`. The SDK locates its own bundle automatically; only apps that looked up the bundle by name themselves need to update that lookup.

## Don't mix package managers

Google Sign-In depends on `AppAuth`, `GTMAppAuth`, `GTMSessionFetcher`, and `AppCheckCore`. If Firebase or another pod in your `Podfile` shares any of those dependencies, migrate them to Swift Package Manager at the same time. Mixing CocoaPods and Swift Package Manager copies of the same library in one target leads to dependency cycles and build errors. See [Firebase's CocoaPods deprecation guide](https://firebase.google.com/docs/ios/cocoapods-deprecation).

## If you can't migrate yet

You can stay on Google Sign-In <FINAL_POD_VERSION> via CocoaPods.

## Cross-platform wrappers

Flutter's `google_sign_in_ios` plugin already ships a `Package.swift` alongside its podspec. For other wrappers (React Native, Unity, etc.), check the plugin's own documentation for its Swift Package Manager support rather than editing its `Podfile` entries directly.
