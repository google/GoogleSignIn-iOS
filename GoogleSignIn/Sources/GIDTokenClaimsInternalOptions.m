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

#import "GIDTokenClaimsInternalOptions.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDTokenClaim.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

@implementation GIDTokenClaimsInternalOptions

+ (nullable NSString *)validatedJSONStringForClaims:(nullable NSSet<GIDTokenClaim *> *)claims
                                              error:(NSError **)error {
  if (!claims || claims.count == 0) {
    return nil;
  }

  // === Step 1: Check for claims with ambiguous essential property. ===
  NSMutableDictionary<NSString *, GIDTokenClaim *> *validTokenClaims =
  [[NSMutableDictionary alloc] init];

  for (GIDTokenClaim *currentClaim in claims) {
    GIDTokenClaim *existingClaim = validTokenClaims[currentClaim.name];

    // Check for a conflict: a claim with the same name but different essentiality.
    if (existingClaim && existingClaim.isEssential != currentClaim.isEssential) {
      if (error) {
        *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                     code:kGIDSignInErrorCodeAmbiguousClaims
                                 userInfo:@{NSLocalizedDescriptionKey: @"The claim was requested as both essential and non-essential. Please provide only one version."}];
      }
      return nil; // Validation failed
    }
    validTokenClaims[currentClaim.name] = currentClaim;
  }

  // === Step 2: Build the dictionary structure required for OIDC JSON ===
  NSMutableDictionary<NSString *, id> *tokenClaimsDictionary = [[NSMutableDictionary alloc] init];
  for (GIDTokenClaim *claim in validTokenClaims.allValues) {
    if (claim.isEssential) {
      tokenClaimsDictionary[claim.name] = @{ @"essential": @YES };
    } else {
      // Per OIDC spec, non-essential claims can be represented by null.
      tokenClaimsDictionary[claim.name] = [NSNull null];
    }
  }
  NSDictionary<NSString *, id> *finalRequestDictionary = @{ @"id_token": tokenClaimsDictionary };

  // === Step 3: Serialize the final dictionary into a JSON string ===
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:finalRequestDictionary
                                                     options:0
                                                       error:error];
  if (!jsonData) {
    return nil;
  }

  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
