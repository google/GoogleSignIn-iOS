// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GoogleSignIn/Tests/Unit/OIDTokenRequest+Testing.h"

#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDScopeUtilities.h>
#endif

@implementation OIDTokenRequest (Testing)

+ (instancetype)testInstance {
  return [self testInstanceWithAdditionalParameters:nil];
}

+ (instancetype)testInstanceWithAdditionalParameters:
    (NSDictionary<NSString *, NSString *> *)additionalParameters {
  OIDAuthorizationResponse *authorizationResponse = [OIDAuthorizationResponse testInstance];
  OIDAuthorizationRequest *authorizationRequest = authorizationResponse.request;
  return [[OIDTokenRequest alloc]
      initWithConfiguration:authorizationResponse.request.configuration
                  grantType:OIDGrantTypeAuthorizationCode
          authorizationCode:authorizationResponse.authorizationCode
                redirectURL:authorizationRequest.redirectURL
                   clientID:authorizationRequest.clientID
               clientSecret:authorizationRequest.clientID
                     scopes:[OIDScopeUtilities scopesArrayWithString:authorizationRequest.scope]
               refreshToken:@"refreshToken"
               codeVerifier:authorizationRequest.codeVerifier
       additionalParameters:additionalParameters];
}

@end
