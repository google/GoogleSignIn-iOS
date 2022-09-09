# Google Sign-In Swift Sample App

## CocoaPods

1. In the `../Samples/Swift/DaysUntilBirthday/` folder, run the following 
[CocoaPods](https://cocoapods.org) command.

```
pod install
```

2. Open the generated workspace:

```
open DaysUntilBirthdayForPod.xcworkspace
```

3. Run the `DaysUntilBirthdayForPod (iOS)` or `DaysUntilBirthdayForPod (macOS)`target.

## Swift Package Manager

1. In the `../Samples/Swift/DaysUntilBirthday/` folder, open the project:

```
open DaysUntilBirthday.xcodeproj
```
2. Run the `DaysUntilBirthday (iOS)` or `DaysUntilBirthday (macOS)` target.

## A Note on running the macOS Sample

If you are running the `DaysUntilBirthday` sample app on macOS, you may see an
error like the below:

```
Error! Optional(Error Domain=com.google.GIDSignIn Code=-2 "keychain error" UserInfo={NSLocalizedDescription=keychain error})
```

This error is related to the signing of the sample app.
You have two choices to remedy the problem.

1. We suggest that you manually manage the signing of the macOS sample app so
that you can provide a provisioning profile. Make sure to select a profile
that is able to sign macOS apps.
2. If you do not have the correct provisioning profile, and are unable to
generate one, then you can add the ["Keychain Sharing" capability](https://developer.apple.com/documentation/xcode/configuring-keychain-sharing)
to the `DaysUntilBirthday (macOS)` target as a workaround.

## Integration Tests

We run integration tests on the `DaysUntilBirthday(iOS)` sample app.
These tests attempt to login via Google Sign-in, and so they need an email and
a password.
The email and password that we use are defined as
[secrets](https://docs.github.com/en/actions/learn-github-actions/contexts#secrets-context)
on our GitHub repo, and we retrieve these from the workflow environment.

Locally, both the email and password need to be passed to `xcodebuild` as
arguments: `xcodebuild <other args> EMAIL_SECRET=... PASSWORD_SECRET=...`.
Refer to the repo's Secrets for these values.
