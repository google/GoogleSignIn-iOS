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

#import "GoogleSignIn/Sources/GIDAuthorizationResponse/GIDAuthorizationResponseHelper.h"

#import "GoogleSignIn/Sources/GIDAuthorizationResponse/API/GIDAuthorizationResponseHandling.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDVerifyAccountDetail.h"

#import "GoogleSignIn/Sources/GIDAuthFlow.h"
#import "GoogleSignIn/Sources/GIDEMMErrorHandler.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <AppAuth/OIDAuthorizationResponse.h>
#import <AppAuth/OIDAuthorizationService.h>
#import <AppAuth/OIDError.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation GIDAuthorizationResponseHelper

- (instancetype)
initWithAuthorizationResponseHandler:(id<GIDAuthorizationResponseHandling>)responseHandler {
  self = [super init];
  if (self) {
    _responseHandler = responseHandler;
  }
  return self;
}

- (void)fetchTokenWithAuthFlow:(GIDAuthFlow *)authFlow {
  [self.responseHandler maybeFetchToken:authFlow];
}

- (GIDAuthFlow *)fetchAuthFlowFromProcessedResponse {
  GIDAuthFlow *authFlow = [self.responseHandler generateAuthFlowFromAuthorizationResponse];

  return authFlow;
}
@end

NS_ASSUME_NONNULL_END
