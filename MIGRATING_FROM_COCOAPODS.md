# Migrating from CocoaPods to Swift Package Manager

CocoaPods trunk becomes read-only on December 2, 2026. Google Sign-In 10.1.0 is the last version published to CocoaPods (both the `GoogleSignIn` and `GoogleSignInSwiftSupport` pods). Existing pod versions remain installable, but future Google Sign-In releases are distributed via Swift Package Manager only.

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

You can stay on Google Sign-In 10.1.0 via CocoaPods.

### Building with Xcode 27

Xcode 27 refuses to build any target whose iOS deployment target is below 15.0. Several of Google Sign-In's transitive pods (`AppCheckCore`, `GoogleUtilities`, `RecaptchaInterop`, `PromisesObjC`, and `PromisesSwift`) still declare lower floors in their podspecs, so a project that installs Google Sign-In through CocoaPods and builds under Xcode 26 fails under Xcode 27 with deployment-target errors in the generated Pods project. Those floors belong to the upstream pods, and Google Sign-In cannot raise them from its own podspec.

Until you migrate, add a `post_install` hook to your `Podfile` that raises the generated Pods targets to your app's own minimum. The sample apps in this repository use the same hook.

```ruby
post_install do |installer|
  # Xcode 27 refuses to build a target whose deployment target is below iOS 15.0.
  # Several transitive pods still declare lower floors in their own podspecs, so
  # raise the generated Pods project targets to match the app's own minimum.
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      ios = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if ios && Gem::Version.new(ios) < Gem::Version.new('15.0')
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
```

Run `pod install` again after adding the hook.

## Cross-platform wrappers

Flutter's `google_sign_in_ios` plugin already ships a `Package.swift` alongside its podspec. For other wrappers (React Native, Unity, etc.), check the plugin's own documentation for its Swift Package Manager support rather than editing its `Podfile` entries directly.
