/*
 * Copyright 2026 Google LLC
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

#import "GoogleSignIn/Sources/GIDEMMAlertPresenter/API/GIDEMMAlertPresenter.h"

NS_ASSUME_NONNULL_BEGIN

/// An in-memory `GIDEMMAlertPresenter` for tests. Records the alert instead of showing it.
@interface GIDFakeEMMAlertPresenter : NSObject <GIDEMMAlertPresenter>

/// The alert passed to the most recent `-presentAlert:overKeyWindow:` that has not yet been
/// dismissed, or nil.
@property(nonatomic, readonly, nullable) UIAlertController *presentedAlert;

/// The key window passed to the most recent `-presentAlert:overKeyWindow:`, or nil.
@property(nonatomic, readonly, nullable) UIWindow *presentedOverKeyWindow;

/// The number of times `-dismissAlert` has been called.
@property(nonatomic, readonly) NSUInteger dismissCount;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
