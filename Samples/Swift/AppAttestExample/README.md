# Google Sign-In with Firebase App Check Sample App

## CocoaPods

1. In the `../Samples/Swift/AppAttestExample/` folder, run the following 
[CocoaPods](https://cocoapods.org) command.

```
pod install
```

2. Open the generated workspace:

```
open AppAttestExample.xcworkspace
```

3. Run the `AppAttestExampleForPod` target.

## Swift Package Manager

1. In the `../Samples/Swift/AppAttestExample/` folder, open the project:

```
open AppAttestExample.xcodeproj
```
2. Run the `AppAttestExample` target.

## A Note on Provisioning Profiles

You will need a provisioning profile with the App Attest entitlement.

## Hiding Secrets

This example app shows how you might hide your web API key and debug token
(used during CI). Inside the `Secrets/` directory, we show a placeholder
secrets file containing stubbed JSON data. You can make a new file to fill in
that stubbed JSON data with your web API key. Make sure to add that new file to
your `.gitignore` so that your secrets are not committed. Next, update
`AppCheckSecretsReader.swift` to read your file.

## Integration Tests

We should how you might hide your app's web API key and debug token when
running locally and in CI environments. See GitHub's
[secrets](https://docs.github.com/en/actions/learn-github-actions/contexts#secrets-context)
documentation for how you might set those values in your repo.

Locally, both the web API key and the debug token need to be passed to 
`xcodebuild` as arguments: 
`xcodebuild <other args> APP_CHECK_WEB_API_KEY=... AppCheckDebugToken=...`.
