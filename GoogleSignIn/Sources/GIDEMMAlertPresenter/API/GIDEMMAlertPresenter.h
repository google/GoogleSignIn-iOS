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

NS_ASSUME_NONNULL_BEGIN

/// Shows and hides the alert that `GIDEMMErrorHandler` uses to explain an EMM error to the user.
///
/// Production code uses `GIDEMMAlertWindowPresenter`; tests use `GIDFakeEMMAlertPresenter`.
@protocol GIDEMMAlertPresenter <NSObject>

/// Presents `alert` above `keyWindow`. Must be called on the main thread.
- (void)presentAlert:(UIAlertController *)alert overKeyWindow:(UIWindow *)keyWindow;

/// Tears down whatever `-presentAlert:overKeyWindow:` set up and makes that call's `keyWindow` the
/// key window again. Must be called on the main thread.
- (void)dismissAlert;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
