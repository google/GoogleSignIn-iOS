/*
 * Copyright 2025 Google LLC
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

extern NSString *const kAuthTimeClaimName;

/**
 * An object representing a single OIDC claim to be requested for an ID token.
 */
@interface GIDClaim : NSObject

/// The name of the claim, e.g., "auth_time".
@property (nonatomic, readonly) NSString *name;

/// Whether the claim is requested as essential.
@property (nonatomic, readonly, getter=isEssential) BOOL essential;

// Making initializers unavailable to force use of factory methods.
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Factory Methods

/// Creates a *non-essential* (voluntary) "auth_time" claim object.
+ (instancetype)authTimeClaim;

/// Creates an *essential* "auth_time" claim object.
+ (instancetype)essentialAuthTimeClaim;

@end

NS_ASSUME_NONNULL_END

