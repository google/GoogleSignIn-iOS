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

#import "AppDelegate.h"

#import "SignInViewController.h"

@import GoogleSignIn;

@implementation AppDelegate

// DO NOT USE THIS CLIENT ID. IT WILL NOT WORK FOR YOUR APP.
// Please use the client ID created for you by Google.
static NSString * const kClientID =
    @"589453917038-qaoga89fitj2ukrsq27ko56fimmojac6.apps.googleusercontent.com";

#pragma mark Object life-cycle.

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Set app's client ID for |GIDSignIn|.
  GIDSignIn.sharedInstance.clientID = kClientID;
  // Restore any previous sign-in session before displaying main view.
  [GIDSignIn.sharedInstance restorePreviousSignInWithCallback:^(GIDGoogleUser * _Nullable user,
                                                                NSError * _Nullable error) {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    SignInViewController *masterViewController =
        [[SignInViewController alloc] initWithNibName:@"SignInViewController"
                                               bundle:nil];
    self.navigationController =
        [[UINavigationController alloc]
            initWithRootViewController:masterViewController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
  }];
  return YES;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
  return [GIDSignIn.sharedInstance handleURL:url];
}


@end
