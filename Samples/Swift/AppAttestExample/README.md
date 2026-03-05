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
(used during CI; AppCheckCore manages the debug token running locally in the 
simulator). Both of these are required. Inside the `Secrets/` directory, we
include a placeholder file entitled `AppCheckDefaultSecrets.xcconfig`. We have
also set that as a configuration file for the project, which means that it will
be used to find the web API key during debug builds on the simulator (for 
example). You can either make a new file to fill in the stubbed data in
`AppCheckDefaultSecrets.xcconfig` (which will require that you update where the
projects finds its configurations), or you can add your API key there yourself.
Do make sure that you do not commit this API key, or you will risk exposing
this information on your repository.

In builds running under continuous integration, make sure to use environment
variables and `AppCheckSecretReader.swift` will find your web API key and debug
token if you provide them to your `xcodebuild` command.

## Integration Tests

We show how you might hide your app's web API key and debug token when
running locally and in CI environments. See GitHub's
[secrets](https://docs.github.com/en/actions/learn-github-actions/contexts#secrets-context)
documentation for how you might set those values in your repo.

Locally, both the web API key and the debug token need to be passed to 
`xcodebuild` as arguments: 
`xcodebuild <other args> APP_CHECK_WEB_API_KEY=... AppCheckDebugToken=...`.
