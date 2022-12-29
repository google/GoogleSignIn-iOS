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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"

@class OIDIDToken;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kBasicProfileEmailKey;
extern NSString *const kBasicProfilePictureKey;
extern NSString *const kBasicProfileNameKey;
extern NSString *const kBasicProfileGivenNameKey;
extern NSString *const kBasicProfileFamilyNameKey;

// Private |GIDProfileData| methods that are used in this SDK.
@interface GIDProfileData ()

// Initialize with profile attributes.
- (instancetype)initWithEmail:(NSString *)email
                         name:(NSString *)name
                    givenName:(nullable NSString *)givenName
                   familyName:(nullable NSString *)familyName
                     imageURL:(nullable NSURL *)imageURL;

/// Initialize with id token.
- (instancetype)initWithIDToken:(OIDIDToken *)idToken;

@end

NS_ASSUME_NONNULL_END
