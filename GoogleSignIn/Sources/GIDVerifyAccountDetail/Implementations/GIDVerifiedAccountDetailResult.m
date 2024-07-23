/*
 * Copyright 2024 Google LLC
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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiedAccountDetailResult.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"

#import "GoogleSignIn/Sources/GIDToken_Private.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDScopeUtilities.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#endif

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_BEGIN

@implementation GIDVerifiedAccountDetailResult

- (instancetype)initWithAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
                             authState:(OIDAuthState *)authState {
  self = [super init];
  if (self) {
    _verifiedAccountDetails = accountDetails;
    _verifiedAuthState = authState;
    _accessToken = 
        [[GIDToken alloc] initWithTokenString:authState.lastTokenResponse.accessToken
                               expirationDate:authState.lastTokenResponse.accessTokenExpirationDate];
    _refreshToken = [[GIDToken alloc] initWithTokenString:authState.refreshToken
                                           expirationDate:nil];
  }
  return self;
}

// TODO: Migrate refresh logic to `GIDGoogleuser` (#441).
- (void)refreshTokensWithCompletion:(nullable void (^)(GIDVerifiedAccountDetailResult *,
                                                      NSError *))completion {
  NSDictionary<NSString *, NSString *> *additionalParameters = 
      self.verifiedAuthState.lastAuthorizationResponse.request.additionalParameters;
  OIDTokenRequest *refreshRequest =
      [self.verifiedAuthState tokenRefreshRequestWithAdditionalHeaders:additionalParameters];

  [OIDAuthorizationService performTokenRequest:refreshRequest
                                      callback:^(OIDTokenResponse * _Nullable tokenResponse, 
                                                 NSError * _Nullable error) {
    if (tokenResponse) {
      [self.verifiedAuthState updateWithTokenResponse:tokenResponse error:nil];
    } else {
      [self.verifiedAuthState updateWithAuthorizationError:error];
    }
    [self updateVerifiedDetailsWithTokenResponse:tokenResponse];
    completion(self, error);
  }];
}

- (void)updateVerifiedDetailsWithTokenResponse:(nullable OIDTokenResponse *)tokenResponse {
  if (tokenResponse) {
    _accessToken = [[GIDToken alloc] initWithTokenString:tokenResponse.accessToken
                                          expirationDate:tokenResponse.accessTokenExpirationDate];

    NSArray<NSString *> *accountDetailsString =
        [OIDScopeUtilities scopesArrayWithString:tokenResponse.scope];
    NSMutableArray<GIDVerifiableAccountDetail *> *verifiedAccountDetails = [NSMutableArray array];
    for (NSString *type in accountDetailsString) {
      GIDAccountDetailType detailType = [GIDVerifiableAccountDetail detailTypeWithString:type];
      if (detailType != GIDAccountDetailTypeUnknown) {
        [verifiedAccountDetails addObject:
         [[GIDVerifiableAccountDetail alloc] initWithAccountDetailType:detailType]];
      }
    }
    _verifiedAccountDetails = [verifiedAccountDetails copy];
  } else {
    _verifiedAccountDetails = @[];
  }
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[GIDVerifiedAccountDetailResult class]]) {
    return NO;
  }

  GIDVerifiedAccountDetailResult *other = (GIDVerifiedAccountDetailResult *)object;
  return [self.accessToken.expirationDate isEqual:other.accessToken.expirationDate] &&
         [self.accessToken.tokenString isEqualToString:other.accessToken.tokenString] &&
         [self.refreshToken.tokenString isEqualToString:other.refreshToken.tokenString] &&
         [self.verifiedAccountDetails isEqual:other.verifiedAccountDetails] &&
         [self.verifiedAuthState isEqual:other.verifiedAuthState];
}

- (NSUInteger)hash {
  return [self.accessToken.expirationDate hash] ^ [self.accessToken.tokenString hash] ^
         [self.refreshToken.tokenString hash] ^ [self.verifiedAccountDetails hash] ^
         [self.verifiedAuthState hash];
}

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
