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

#import "GoogleSignIn/Sources/GIDEMMAlertPresenter/Implementation/GIDEMMAlertWindowPresenter.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@implementation GIDEMMAlertWindowPresenter {
  UIWindow *_alertWindow;
  UIWindow *_keyWindow;
}

- (void)presentAlert:(UIAlertController *)alert overKeyWindow:(UIWindow *)keyWindow {
  _keyWindow = keyWindow;
  UIWindow *alertWindow;
  if (keyWindow.windowScene) {
    alertWindow = [[UIWindow alloc] initWithWindowScene:keyWindow.windowScene];
  }
  if (!alertWindow) {
    CGRect keyWindowBounds = CGRectIsEmpty(keyWindow.bounds) ?
        keyWindow.bounds : [UIScreen mainScreen].bounds;
    alertWindow = [[UIWindow alloc] initWithFrame:keyWindowBounds];
  }
  alertWindow.backgroundColor = [UIColor clearColor];
  alertWindow.rootViewController = [[UIViewController alloc] init];
  alertWindow.rootViewController.view.backgroundColor = [UIColor clearColor];
  alertWindow.windowLevel = UIWindowLevelAlert;
  [alertWindow makeKeyAndVisible];
  _alertWindow = alertWindow;
  [alertWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)dismissAlert {
  _alertWindow.hidden = YES;
  _alertWindow.rootViewController = nil;
  _alertWindow = nil;
  [_keyWindow makeKeyAndVisible];
  _keyWindow = nil;
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
