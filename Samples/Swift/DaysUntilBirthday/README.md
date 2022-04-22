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
The email and password that we use are located in `Credentials.xcconfig`.

We create this file during a workflow step on PR push by retrieving these values
from [GitHub's Secret's context](https://docs.github.com/en/actions/learn-github-actions/contexts#secrets-context).

Locally, both email and password are retrived from a `Credentials.xcconfig`
configuration file that is not checked into the repo.
You will need to create an `Credentials.xcconfig` at this path:
`Samples/Swift/DaysUntilBirthday/DaysUnilBirthdayUITests(iOS)/Credentials.xcconfig`.
It will need values for `EMAIL_SECRET` and `PASSWORD_SECRET`:

```
EMAIL_SECRET = ...
PASSWORD_SECRET = ...
```

Refer to the repo's Secrets for the values to add to this configuration file.
