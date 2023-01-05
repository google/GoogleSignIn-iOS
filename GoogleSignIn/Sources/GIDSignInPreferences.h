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

NS_ASSUME_NONNULL_BEGIN

// The name of the query parameter used for logging the SDK version.
extern NSString *const kSDKVersionLoggingParameter;

// The name of the query parameter used for logging the Apple execution environment.
extern NSString *const kEnvironmentLoggingParameter;

// Expected path in the URL scheme to be handled.
extern NSString *const kBrowserCallbackPath;

NSString* GIDVersion(void);

NSString* GIDEnvironment(void);

@interface GIDSignInPreferences : NSObject

+ (NSString *)googleAuthorizationServer;

+ (NSString *)googleTokenServer;

+ (NSString *)googleUserInfoServer;

+ (NSURL *)authorizationEndpointURL;

+ (NSURL *)tokenEndpointURL;

@end

NS_ASSUME_NONNULL_END
