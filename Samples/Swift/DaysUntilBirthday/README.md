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
