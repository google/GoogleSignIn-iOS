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

@class GIDConfiguration;
@class GIDGoogleUser;

NS_ASSUME_NONNULL_BEGIN

/// The error domain for `NSError`s returned by the Google Sign-In SDK.
extern NSErrorDomain const kGIDSignInErrorDomain;

/// A list of potential error codes returned from the Google Sign-In SDK.
typedef NS_ERROR_ENUM(kGIDSignInErrorDomain, GIDSignInErrorCode) {
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
  /// Indicates there is no `currentUser`.
  kGIDSignInErrorCodeNoCurrentUser = -7,
  /// Indicates the requested scopes have already been granted to the `currentUser`.
  kGIDSignInErrorCodeScopesAlreadyGranted = -8,
};

/// Represents a callback block that takes a `GIDGoogleUser` on success or an error if the operation
/// was unsuccessful.
typedef void (^GIDSignInCallback)(GIDGoogleUser *_Nullable user, NSError *_Nullable error);

/// Represents a callback block that takes an error if the operation was unsuccessful.
typedef void (^GIDDisconnectCallback)(NSError *_Nullable error);

/// This class signs the user in with Google.
///
/// For reference, please see "Google Sign-In for iOS" at
/// https://developers.google.com/identity/sign-in/ios
@interface GIDSignIn : NSObject

/// A shared `GIDSignIn` instance.
@property(class, nonatomic, readonly) GIDSignIn *sharedInstance;

/// The `GIDGoogleUser` object representing the current user or `nil` if there is no signed-in user.
@property(nonatomic, readonly, nullable) GIDGoogleUser *currentUser;

/// Unavailable. Use the `sharedInstance` property to instantiate `GIDSignIn`.
/// :nodoc:
+ (instancetype)new NS_UNAVAILABLE;

/// Unavailable. Use the `sharedInstance` property to instantiate `GIDSignIn`.
/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

/// This method should be called from your `UIApplicationDelegate`'s `application:openURL:options:`
/// method.
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
/// @param callback The `GIDSignInCallback` block that is called on completion.  This block will be
///     called asynchronously on the main queue.
- (void)restorePreviousSignInWithCallback:(nullable GIDSignInCallback)callback;

/// Starts an interactive sign-in flow using the provided configuration.
///
/// The callback will be called at the end of this process.  Any saved sign-in state will be
/// replaced by the result of this flow.  Note that this method should not be called when the app is
/// starting up, (e.g in `application:didFinishLaunchingWithOptions:`); instead use the
/// `restorePreviousSignInWithCallback:` method to restore a previous sign-in.
///
/// @param configuration The configuration properties to be used for this flow.
/// @param presentingViewController The view controller used to present `SFSafariViewContoller` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param callback The `GIDSignInCallback` block that is called on completion.  This block will be
///     called asynchronously on the main queue.
- (void)signInWithConfiguration:(GIDConfiguration *)configuration
       presentingViewController:(UIViewController *)presentingViewController
                       callback:(nullable GIDSignInCallback)callback
    NS_EXTENSION_UNAVAILABLE("The sign-in flow is not supported in App Extensions.");

/// Starts an interactive sign-in flow using the provided configuration and a login hint.
///
/// The callback will be called at the end of this process.  Any saved sign-in state will be
/// replaced by the result of this flow.  Note that this method should not be called when the app is
/// starting up, (e.g in `application:didFinishLaunchingWithOptions:`); instead use the
/// `restorePreviousSignInWithCallback:` method to restore a previous sign-in.
///
/// @param configuration The configuration properties to be used for this flow.
/// @param presentingViewController The view controller used to present `SFSafariViewContoller` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param callback The `GIDSignInCallback` block that is called on completion.  This block will be
///     called asynchronously on the main queue.
- (void)signInWithConfiguration:(GIDConfiguration *)configuration
       presentingViewController:(UIViewController *)presentingViewController
                           hint:(nullable NSString *)hint
                       callback:(nullable GIDSignInCallback)callback
    NS_EXTENSION_UNAVAILABLE("The sign-in flow is not supported in App Extensions.");

/// Starts an interactive consent flow to add scopes to the current user's grants.
///
/// The callback will be called at the end of this process.  If successful, a new `GIDGoogleUser`
/// instance will be returned reflecting the new scopes and saved sign-in state will be updated.
///
/// @param scopes The scopes to ask the user to consent to.
/// @param presentingViewController The view controller used to present `SFSafariViewContoller` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param callback The `GIDSignInCallback` block that is called on completion.  This block will be
///     called asynchronously on the main queue.
- (void)addScopes:(NSArray<NSString *> *)scopes
    presentingViewController:(UIViewController *)presentingViewController
                    callback:(nullable GIDSignInCallback)callback
    NS_EXTENSION_UNAVAILABLE("The add scopes flow is not supported in App Extensions."); 

/// Marks current user as being in the signed out state.
- (void)signOut;

/// Disconnects the current user from the app and revokes previous authentication. If the operation
/// succeeds, the OAuth 2.0 token is also removed from keychain.
///
/// @param callback The optional `GIDDisconnectCallback` block that is called on completion.  This
///     block will be called asynchronously on the main queue.
- (void)disconnectWithCallback:(nullable GIDDisconnectCallback)callback;

@end

NS_ASSUME_NONNULL_END
