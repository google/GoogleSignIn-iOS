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

#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"

#import "GoogleSignIn/Tests/Unit/OIDServiceConfiguration+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDAuthorizationRequest.h>
#import <AppAuth/OIDResponseTypes.h>
#import <AppAuth/OIDServiceConfiguration.h>
#endif

NSString *const OIDAuthorizationRequestTestingClientID = @"87654321.googleusercontent.com";
NSString *const OIDAuthorizationRequestTestingScope = @"email";
NSString *const OIDAuthorizationRequestTestingScope2 = @"profile";
NSString *const OIDAuthorizationRequestTestingCodeVerifier = @"codeVerifier";

@implementation OIDAuthorizationRequest (Testing)

+ (instancetype)testInstance {
  return [[OIDAuthorizationRequest alloc]
      initWithConfiguration:[OIDServiceConfiguration testInstance]
                   clientId:OIDAuthorizationRequestTestingClientID
                     scopes:@[ OIDAuthorizationRequestTestingScope,
                               OIDAuthorizationRequestTestingScope2 ]
                redirectURL:[NSURL URLWithString:@"http://test.com"]
               responseType:OIDResponseTypeCode
       additionalParameters:nil];
}

@end
