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

#import "GoogleSignIn/Tests/Unit/OIDAuthorizationResponse+Testing.h"

#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDGrantTypes.h>
#endif

@implementation OIDAuthorizationResponse (Testing)

+ (instancetype)testInstance {
  return [self testInstanceWithAdditionalParameters:nil errorString:nil];
}

+ (instancetype)testInstanceWithAdditionalParameters:
    (NSDictionary<NSString *, NSString *> *)additionalParameters
                                         errorString:(NSString *)errorString {

  NSMutableDictionary<NSString *, NSString *> *parameters;
  if (errorString) {
    parameters = [NSMutableDictionary dictionaryWithDictionary:@{ @"error" : errorString }];
  } else {
    parameters = [NSMutableDictionary dictionaryWithDictionary:@{
      @"code" : @"authorization_code",
      @"state" : @"state",
      @"token_type" : OIDGrantTypeAuthorizationCode,
    }];
    if (additionalParameters) {
      [parameters addEntriesFromDictionary:additionalParameters];
    }
  }
  return [[OIDAuthorizationResponse alloc] initWithRequest:[OIDAuthorizationRequest testInstance]
                                                parameters:parameters];
}

@end
