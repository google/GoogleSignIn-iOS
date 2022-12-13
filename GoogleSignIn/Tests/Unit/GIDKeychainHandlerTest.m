// Copyright 2022 Google LLC
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

#import "GoogleSignIn/Sources/GIDKeychainHandler/Implementations/GIDKeychainHandler.h"

#import <XCTest/XCTest.h>

#import "GoogleSignIn/Tests/Unit/OIDAuthState+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
@import OCMock;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <OCMock/OCMock.h>
#endif

static NSTimeInterval const kIDTokenExpiresIn = 100;

@interface GIDKeychainHandlerTest : XCTestCase {
  GIDKeychainHandler *_keychainHandler;
  id _authorization;
}

@end

@implementation GIDKeychainHandlerTest

- (void)setUp {
  _keychainHandler = [[GIDKeychainHandler alloc] init];
  _authorization = OCMStrictClassMock([GTMAppAuthFetcherAuthorization class]);
}

- (void)testLoadAuthState {
  [_keychainHandler loadAuthState];
  [[_authorization verify] authorizationFromKeychainForName:[OCMArg any]
                                  useDataProtectionKeychain:YES];
}

- (void)testSaveAuthState {
  NSString *idToken = [self idTokenWithExpiresIn:kIDTokenExpiresIn];
  OIDAuthState *authState = [OIDAuthState testInstanceWithIDToken:idToken
                                                      accessToken:kAccessToken
                                             accessTokenExpiresIn:kAccessTokenExpiresIn
                                                     refreshToken:kRefreshToken];

  [_keychainHandler saveAuthState:authState];
  [[_authorization verify] saveAuthorization:[OCMArg any]
                           toKeychainForName:[OCMArg any]
                   useDataProtectionKeychain:YES];
}

- (void)testRemoveAllKeychainEntries {
  [_keychainHandler removeAllKeychainEntries];
  [[_authorization verify] removeAuthorizationFromKeychainForName:[OCMArg any]
                                        useDataProtectionKeychain:YES];
}

#pragma mark - Helpers

- (NSString *)idTokenWithExpiresIn:(NSTimeInterval)expiresIn {
  // The expireTime should be based on 1970.
  NSTimeInterval expireTime = [[NSDate date] timeIntervalSince1970] + expiresIn;
  return [OIDTokenResponse idTokenWithSub:kUserID exp:@(expireTime)];
}

@end
