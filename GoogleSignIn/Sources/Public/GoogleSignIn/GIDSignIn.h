/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class GIDGoogleUser;
@class GIDSignIn;

NS_ASSUME_NONNULL_BEGIN

/// The error domain for `NSError`s returned by the Google Identity SDK.
extern NSString *const kGIDSignInErrorDomain;

/// A list of potential error codes returned from the Google Identity SDK.
typedef NS_ENUM(NSInteger, GIDSignInErrorCode) {
  /// Indicates an unknown error has occurred.
  kGIDSignInErrorCodeUnknown = -1,
  /// Indicates a problem reading or writing to the application keychain.
  kGIDSignInErrorCodeKeychain = -2,
  /// Indicates there are no valid auth tokens in the keychain. This error code will be returned by
  /// `restorePreviousSignIn` if the user has not signed in before or if they have since signed out.
  kGIDSignInErrorCodeHasNoAuthInKeychain = -4,
  /// Indicates the user canceled the sign in request.
  kGIDSignInErrorCodeCanceled = -5,
  /// Indicates an Enterprise Mobility Management related error has occurred.
  kGIDSignInErrorCodeEMM = -6,
};

/// Represents a callback block that takes a `GIDGoogleUser` or an error if the operation was
/// unsuccessful.
typedef void (^GIDSignInCallback)(GIDGoogleUser *_Nullable user, NSError *_Nullable error);

/// A protocol implemented by the delegate of `GIDSignIn` to receive a refresh token or an error.
@protocol GIDSignInDelegate <NSObject>

/// The sign-in flow has finished and was successful if `error` is `nil`.
- (void)signIn:(GIDSignIn *)signIn
    didSignInForUser:(nullable GIDGoogleUser *)user
           withError:(nullable NSError *)error;

@optional

/// Finished disconnecting `user` from the app successfully if `error` is `nil`.
- (void)signIn:(GIDSignIn *)signIn
    didDisconnectWithUser:(nullable GIDGoogleUser *)user
                withError:(nullable NSError *)error;

@end

/// This class signs the user in with Google. It also provides single sign-on via a capable Google
/// app if one is installed.
///
/// For reference, please see "Google Sign-In for iOS" at
/// https://developers.google.com/identity/sign-in/ios
///
/// Here is sample code to use `GIDSignIn`:
/// 1. Get a reference to the `GIDSignIn` shared instance:
///    ```
///    GIDSignIn *signIn = [GIDSignIn sharedInstance];
///    ```
/// 2. Call `[signIn setDelegate:self]`;
/// 3. Set up delegate method `signIn:didSignInForUser:withError:`.
/// 4. Call `handleURL` on the shared instance from `application:openUrl:...` in your app delegate.
/// 5. Call `signIn` on the shared instance;
@interface GIDSignIn : NSObject

/// The authentication object for the current user, or `nil` if there is currently no logged in
/// user.
@property(nonatomic, readonly, nullable) GIDGoogleUser *currentUser;

/// The object to be notified when authentication is finished.
@property(nonatomic, weak, nullable) id<GIDSignInDelegate> delegate;

/// The view controller used to present `SFSafariViewContoller` on iOS 9 and 10.
@property(nonatomic, weak, nullable) UIViewController *presentingViewController;

/// The client ID of the app from the Google APIs console.  Must set for sign-in to work.
@property(nonatomic, copy, nullable) NSString *clientID;

/// The API scopes requested by the app in an array of `NSString`s.  The default value is `@[]`.
///
/// This property is optional. If you set it, set it before calling `signIn`.
@property(nonatomic, copy, nullable) NSArray<NSString *> *scopes;

/// Whether or not to fetch basic profile data after signing in. The data is saved in the
/// `GIDGoogleUser.profileData` object.
///
/// Setting the flag will add "email" and "profile" to scopes.
/// Defaults to `YES`.
@property(nonatomic, assign) BOOL shouldFetchBasicProfile;

/// The login hint to the authorization server, for example the user's ID, or email address,
/// to be prefilled if possible.
///
/// This property is optional. If you set it, set it before calling `signIn`.
@property(nonatomic, copy, nullable) NSString *loginHint;

/// The client ID of the home web server.  This will be returned as the `audience` property of the
/// OpenID Connect ID token.  For more info on the ID token:
/// https://developers.google.com/identity/sign-in/ios/backend-auth
///
/// This property is optional. If you set it, set it before calling `signIn`.
@property(nonatomic, copy, nullable) NSString *serverClientID;

/// The OpenID2 realm of the home web server. This allows Google to include the user's OpenID
/// Identifier in the OpenID Connect ID token.
///
/// This property is optional. If you set it, set it before calling `signIn`.
@property(nonatomic, copy, nullable) NSString *openIDRealm;

/// The Google Apps domain to which users must belong to sign in.  To verify, check
/// `GIDGoogleUser`'s `hostedDomain` property.
///
/// This property is optional. If you set it, set it before calling `signIn`.
@property(nonatomic, copy, nullable) NSString *hostedDomain;

/// Returns a shared `GIDSignIn` instance.
+ (GIDSignIn *)sharedInstance;

/// Unavailable. Use `sharedInstance` to instantiate `GIDSignIn`.
+ (instancetype)new NS_UNAVAILABLE;

/// Unavailable. Use `sharedInstance` to instantiate `GIDSignIn`.
- (instancetype)init NS_UNAVAILABLE;

/// This method should be called from your `UIApplicationDelegate`'s `application:openURL:options`
/// and `application:openURL:sourceApplication:annotation` method(s).
///
/// @param url The URL that was passed to the app.
/// @return `YES` if `GIDSignIn` handled this URL.
- (BOOL)handleURL:(NSURL *)url;

/// Checks if there is a previously authenticated user saved in keychain.
///
/// @return `YES` if there is a previously authenticated user saved in keychain.
- (BOOL)hasPreviousSignIn;

/// Attempts to restore a previously authenticated user without interaction.
///
/// @param callback The `GIDSignInCallback` block that is called on completion.
- (void)restorePreviousSignInWithCallback:(GIDSignInCallback)callback;

/// Starts an interactive sign-in flow using `GIDSignIn`'s configuration properties.
///
/// The delegate will be called at the end of this process.  Any saved sign-in state will be
/// replaced by the result of this flow.  Note that this method should not be called when the app is
/// starting up, (e.g in `application:didFinishLaunchingWithOptions:`); instead use the
/// `restorePreviousSignIn` method to restore a previous sign-in.
- (void)signIn;

/// Marks current user as being in the signed out state.
- (void)signOut;

/// Disconnects the current user from the app and revokes previous authentication. If the operation
/// succeeds, the OAuth 2.0 token is also removed from keychain.
///
/// @param callback The `GIDSignInCallback` block that is called on completion.
- (void)disconnectWithCallback:(GIDSignInCallback)callback;

@end

NS_ASSUME_NONNULL_END
