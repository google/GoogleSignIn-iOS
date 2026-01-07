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

@class GIDClaim;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kGIDClaimErrorDescription;
extern NSString *const kGIDClaimEssentialPropertyKeyName;
extern NSString *const kGIDClaimKeyName;

@protocol GIDJSONSerializer;

/**
 * An internal utility class for processing and serializing the `NSSet` of `GIDClaim` objects
 * into the `JSON` format required for an `OIDAuthorizationRequest`.
 */
@interface GIDClaimsInternalOptions : NSObject

- (instancetype)init;

- (instancetype)initWithJSONSerializer:
    (id<GIDJSONSerializer>)jsonSerializer NS_DESIGNATED_INITIALIZER;

/**
 * Processes the `NSSet` of `GIDClaim` objects, handling ambiguous claims,
 * and returns a `JSON` string.
 *
 * @param claims The `NSSet` of `GIDClaim` objects provided by the developer.
 * @param error A pointer to an `NSError` object to be populated if an error occurs (e.g., if a
 * claim is requested as both essential and non-essential).
 * @return A `JSON` string representing the claims request, or `nil` if the input is empty or an
 * error occurs.
 */
- (nullable NSString *)validatedJSONStringForClaims:(nullable NSSet<GIDClaim *> *)claims
                                              error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
