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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

@class GIDConfiguration;

NS_ASSUME_NONNULL_BEGIN

/// The options used internally for aspects of the sign-in flow.
@interface GIDSignInInternalOptions : NSObject

/// Whether interaction with user is allowed at all.
@property(nonatomic, readonly) BOOL interactive;

/// Whether the sign-in is a continuation of the previous one.
@property(nonatomic, readonly) BOOL continuation;

/// The extra parameters used in the sign-in URL.
@property(nonatomic, readonly, nullable) NSDictionary *extraParams;

/// The configuration to use during the flow.
@property(nonatomic, readonly, nullable) GIDConfiguration *configuration;

/// The the view controller to use during the flow.
@property(nonatomic, readonly, weak, nullable) UIViewController *presentingViewController;

/// The callback block to be called at the completion of the flow.
@property(nonatomic, readonly, nullable) GIDSignInCallback callback;

/// The scopes to be used during the flow.
@property(nonatomic, copy, nullable) NSArray<NSString *> *scopes;

/// The login hint to be used during the flow.
@property(nonatomic, copy, nullable) NSString *loginHint;

/// Creates the default options.
+ (instancetype)defaultOptionsWithConfiguration:(nullable GIDConfiguration *)configuration
                       presentingViewController:
                           (nullable UIViewController *)presentingViewController
                                      loginHint:(nullable NSString *)loginHint
                                       callback:(GIDSignInCallback)callback;

/// Creates the options to sign in silently.
+ (instancetype)silentOptionsWithCallback:(GIDSignInCallback)callback;

/// Creates options with the same values as the receiver, except for the "extra parameters", and
/// continuation flag, which are replaced by the arguments passed to this method.
- (instancetype)optionsWithExtraParameters:(NSDictionary *)extraParams
                           forContinuation:(BOOL)continuation;

@end

NS_ASSUME_NONNULL_END
