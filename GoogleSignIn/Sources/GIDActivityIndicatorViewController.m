/*
 * Copyright 2023 Google LLC
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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import "GIDActivityIndicatorViewController.h"

@interface GIDActivityIndicatorViewController ()

@end

@implementation GIDActivityIndicatorViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
  self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
  [self.activityIndicator startAnimating];
  [self.view addSubview:self.activityIndicator];

  NSLayoutConstraint *centerX =
      [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
  NSLayoutConstraint *centerY =
      [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
  [NSLayoutConstraint activateConstraints:@[centerX, centerY]];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
