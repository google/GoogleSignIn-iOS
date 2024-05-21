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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#elif __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class GIDConfiguration;
@class GIDVerifiableAccountDetail;
@class GIDVerifiedAccountDetailResult;

/// The error domain for `NSError`s returned by the Google Sign-In SDK.
extern NSErrorDomain const kGIDVerifyErrorDomain;

/// A list of potential error codes returned from the Google Sign-In SDK.
typedef NS_ERROR_ENUM(kGIDVerifyErrorDomain, GIDVerifyErrorCode) {
  /// Indicates an unknown error has occurred.
  GIDVerifyErrorCodeUnknown = 0,
  /// Indicates the user canceled the verification request.
  GIDVerifyErrorCodeCanceled = 1,
};

/// Represents a completion block that takes a `GIDVerifiedAccountDetailResult` on success or an
/// error if the operation was unsuccessful.
typedef void (^GIDVerifyCompletion)(GIDVerifiedAccountDetailResult *_Nullable verifiedResult,
                                    NSError *_Nullable error);

/// This class is used to verify a user's Google account details.
@interface GIDVerifyAccountDetail : NSObject

/// The active configuration for this instance of `GIDVerifyAccountDetail`.
@property(nonatomic, nullable) GIDConfiguration *configuration;

/// Initialize a `GIDVerifyAccountDetail` object by specifying all available properties.
///
/// @param config The configuration to be used.
/// @return An initialized `GIDVerifyAccountDetail` instance.
- (instancetype)initWithConfig:(GIDConfiguration *)config
    NS_DESIGNATED_INITIALIZER;


/// Initialize a `GIDVerifyAccountDetail` object by calling the designated initializer 
/// with the default configuration from the bundle's Info.plist.
///
/// @return An initialized `GIDVerifyAccountDetail` instance.
///     Otherwise, `nil` if the configuration cannot be automatically generated from your app's Info.plist.
- (instancetype)init;

/// Starts an interactive verification flow.
///
/// The completion will be called at the end of this process.  Any saved verification
/// state will be replaced by the result of this flow.
///
/// @param accountDetails A list of verifiable account details.
/// @param presentingViewController The view controller used to present the flow.
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
/// @param presentingViewController The view controller used to present the flow.
/// @param hint An optional hint for the authorization server, for example the user's ID or email
///     address, to be prefilled if possible.
/// @param completion The optional block called asynchronously on the main queue upon completion.
- (void)verifyAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
    presentingViewController:(UIViewController *)presentingViewController
                        hint:(nullable NSString *)hint
                  completion:(nullable void (^)(GIDVerifiedAccountDetailResult *_Nullable verifyResult,
                                                NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
