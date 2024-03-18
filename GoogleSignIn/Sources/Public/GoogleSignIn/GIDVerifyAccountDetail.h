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

@class GIDVerifiableAccountDetail;
@class GIDVerifiedAccountDetailResult;

NS_ASSUME_NONNULL_BEGIN

/// This class is used to verify a user's Googleaccount details.
@interface GIDVerifyAccountDetail : NSObject

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

/// Starts an interactive verify flow on iOS.
///
/// The completion will be called at the end of this process.  Any saved verify state will be
/// replaced by the result of this flow.
///
/// @param accountDetails A list of verifiable account details.
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param completion The optional block that is called on completion.  This block will
///     be called asynchronously on the main queue.
- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails 
         presentingViewController:(UIViewController *)presentingViewController 
                       completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult, 
                                                   NSError *_Nullable error))completion;

/// Starts an interactive verify flow on iOS using the provided hint.
///
/// The completion will be called at the end of this process.  Any saved verify state will be
/// replaced by the result of this flow.
///
/// @param accountDetails A list of verifiable account details.
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10 and to supply `presentationContextProvider` for `ASWebAuthenticationSession` on
///     iOS 13+.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param completion The optional block that is called on completion.  This block will
///     be called asynchronously on the main queue.
- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails 
         presentingViewController:(UIViewController *)presentingViewController 
                             hint:(nullable NSString *)hint
                       completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult, 
                                                   NSError *_Nullable error))completion;

/// Starts an interactive verify flow on iOS using the provided hint and additional scopes.
///
/// The completion will be called at the end of this process.  Any saved verify state will be
/// replaced by the result of this flow. 
///
/// @param accountDetails A list of verifiable account details.
/// @param presentingViewController The view controller used to present `SFSafariViewController` on
///     iOS 9 and 10.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param additionalScopes An optional array of scopes to request in addition to the basic profile scopes.
/// @param completion The optional block that is called on completion.  This block will
///     be called asynchronously on the main queue.
- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails 
         presentingViewController:(UIViewController *)presentingViewController 
                             hint:(nullable NSString *)hint
                          additionalScopes:(nullable NSArray<NSString *> *)additionalScopes
                       completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult, 
                                                   NSError *_Nullable error))completion;

#endif

@end

NS_ASSUME_NONNULL_END
