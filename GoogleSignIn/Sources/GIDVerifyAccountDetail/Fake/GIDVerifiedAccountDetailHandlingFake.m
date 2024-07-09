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

#import "GoogleSignIn/Sources/GIDVerifyAccountDetail/Fake/GIDVerifiedAccountDetailHandlingFake.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiableAccountDetail.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifiedAccountDetailResult.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDTokenResponse.h>
#import <AppAuth/OIDScopeUtilities.h>
#endif

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@implementation GIDVerifiedAccountDetailHandlingFake

- (instancetype)initWithAccountDetails:(NSArray<GIDVerifiableAccountDetail *> *)accountDetails
                             authState:(OIDAuthState *)authState {
  self = [super init];
  if (self) {
    NSAssert(false, @"This class is only to be used in testing. Do not use.");
  }
  return self;
}

- (instancetype)initWithTokenResponse:(nullable OIDTokenResponse *)tokenResponse
                    verifiedAuthState:(nullable OIDAuthState *)verifiedAuthState
                                error:(nullable NSError *)error {
  self = [super init];
  if (self) {
    _tokenResponse = tokenResponse;
    _verifiedAuthState = verifiedAuthState;
    _error = error;
  }
  return self;
}

- (void)refreshTokensWithCompletion:(nullable void (^)(GIDVerifiedAccountDetailResult *,
                                                      NSError *))completion {
  if (_tokenResponse) {
    [self.verifiedAuthState updateWithTokenResponse:_tokenResponse error:nil];
  } else {
    [self.verifiedAuthState updateWithAuthorizationError:_error];
  }

  [self updateVerifiedDetailsWithTokenResponse:_tokenResponse];

  GIDVerifiedAccountDetailResult *result =
      [[GIDVerifiedAccountDetailResult alloc] initWithAccountDetails:_verifiedAccountDetails
                                                           authState:_verifiedAuthState];
  completion(result, _error);
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

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
