/*
 * Copyright 2024 Google LLC
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
#import <TargetConditionals.h>

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#elif __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class GIDVerifiableAccountDetail;
@class GIDVerifiedAccountDetailResult;

#if TARGET_OS_IOS
/// Represents a completion block that takes a `GIDVerifiedAccountDetailResult` on success or an
/// error if the operation was unsuccessful.
typedef void (^GIDVerifyCompletion)(GIDVerifiedAccountDetailResult *_Nullable verifiedResult,
                                    NSError *_Nullable error);
#endif // TARGET_OS_IOS

/// This class is used to verify a user's Google account details.
@interface GIDVerifyAccountDetail : NSObject

#if TARGET_OS_IOS

/// Starts an interactive verification flow.
///
/// The completion will be called at the end of this process.  Any saved verification
/// state will be replaced by the result of this flow.
///
/// @param accountDetails A list of verifiable account details.
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param completion The optional block called asynchronously on the main queue upon completion.
- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
    presentingViewController:(UIViewController *)presentingViewController
                  completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult,
                                                NSError *_Nullable error))completion;

/// Starts an interactive verification flow using the provided hint.
///
/// The completion will be called at the end of this process.  Any saved verification
/// state will be replaced by the result of this flow.
///
/// @param accountDetails A list of verifiable account details.
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param completion The optional block called asynchronously on the main queue upon completion.
- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
    presentingViewController:(UIViewController *)presentingViewController
                        hint:(nullable NSString *)hint
                  completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult,
                                                NSError *_Nullable error))completion;

/// Starts an interactive verification flow using the provided hint and additional scopes.
///
/// The completion will be called at the end of this process.  Any saved verification
/// state will be replaced by the result of this flow.
///
/// @param accountDetails A list of verifiable account details.
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param additionalScopes An optional array of scopes to request in addition to the basic profile scopes.
/// @param completion The optional block called asynchronously on the main queue upon completion.
- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
    presentingViewController:(UIViewController *)presentingViewController
                        hint:(nullable NSString *)hint
            additionalScopes:(nullable NSArray<NSString *> *)additionalScopes
                  completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult,
                                                NSError *_Nullable error))completion;

#endif // TARGET_OS_IOS

@end

NS_ASSUME_NONNULL_END
