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
#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "GoogleSignIn/Sources/GIDApplication/API/GIDApplication.h"
#import "GoogleSignIn/Sources/GIDEMMAlertPresenter/API/GIDEMMAlertPresenter.h"

NS_ASSUME_NONNULL_BEGIN

// The handler for displaying EMM-specific errors to users.
@interface GIDEMMErrorHandler : NSObject

// Retrieve the shared instance of this class.
+ (instancetype)sharedInstance;

// Creates a handler that finds the key window and opens URLs through `application`, and shows its
// alerts through `alertPresenter`.
- (instancetype)initWithApplication:(id<GIDApplication>)application
                     alertPresenter:(id<GIDEMMAlertPresenter>)alertPresenter
    NS_DESIGNATED_INITIALIZER;

// Creates a handler backed by `UIApplication.sharedApplication` and a `GIDEMMAlertWindowPresenter`.
- (instancetype)init;

// Returns the application's key window, or nil if there is none.
// Exposed for the unit tests.
- (nullable UIWindow *)keyWindow;

// Handles EMM-specific errors in the server |response|. |completion| is always called
// exactly once, asynchronously on the main thread, with |YES| if |response| carries an EMM
// error and |NO| otherwise. For an EMM error, a remediation dialog is presented and
// |completion| is called after the user dismisses it — unless another EMM dialog is already
// pending or no dialog can be presented, in which case it is called as soon as possible.
- (void)handleErrorFromResponse:(NSDictionary<NSString *, id> *)response
                     completion:(void (^)(BOOL handled))completion;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
