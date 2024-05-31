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

@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMSessionFetcherCore;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDScopeUtilities.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation GIDVerifiedAccountDetailResult

- (instancetype)initWithLastTokenResponse:(OIDTokenResponse *)tokenResponse
                           accountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
                                authState:(OIDAuthState *)authState {
  self = [super init];
  if (self) {
    _expirationDate = tokenResponse.accessTokenExpirationDate;
    _accessTokenString = tokenResponse.accessToken;
    _refreshTokenString = tokenResponse.refreshToken;
    _verifiedAccountDetails = accountDetails;
    _verifiedAuthState = authState;
  }
  return self;
}

- (void)refreshTokensWithCompletion:(nullable void (^)(GIDVerifiedAccountDetailResult *,
                                                      NSError *))completion {
  OIDAuthorizationResponse *authResponse = self.verifiedAuthState.lastAuthorizationResponse;
  OIDAuthorizationRequest *request = authResponse.request;

  OIDTokenRequest *refreshRequest = 
      [[OIDTokenRequest alloc] initWithConfiguration:request.configuration
                                           grantType:OIDGrantTypeAuthorizationCode
                                   authorizationCode:authResponse.authorizationCode
                                         redirectURL:request.redirectURL
                                            clientID:request.clientID
                                        clientSecret:request.clientSecret
                                               scope:request.scope                     
                                        refreshToken:self.refreshTokenString
                                        codeVerifier:request.codeVerifier
                                additionalParameters:request.additionalParameters];

  [OIDAuthorizationService performTokenRequest:refreshRequest
                 originalAuthorizationResponse:authResponse
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

- (void)updateVerifiedDetailsWithTokenResponse:(nullable OIDTokenResponse *)response {
  if (response) {
    NSArray<NSString *> *accountDetailsString = 
        [OIDScopeUtilities scopesArrayWithString:response.scope];

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

@end
NS_ASSUME_NONNULL_END
