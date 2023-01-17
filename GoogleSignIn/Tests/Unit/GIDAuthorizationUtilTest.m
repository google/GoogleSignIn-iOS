// Copyright 2023 Google LLC
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

#import <TargetConditionals.h>

#import <XCTest/XCTest.h>

#import "GoogleSignIn/Sources/GIDAuthorizationUtil.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

static NSString * const kClientId = @"FakeClientID";
static NSString * const kUserEmail = @"FakeUserEmail";
static NSString * const kServerClientId = @"FakeServerClientID";

static NSString * const kScopeBirthday = @"birthday";
static NSString * const kScopeEmail = @"email";
static NSString * const kScopeProfile = @"profile";

@interface GIDAuthorizationUtilTest : XCTestCase

@end

@implementation GIDAuthorizationUtilTest {
  GIDConfiguration *_configuration;
}

- (void)setUp {
  [super setUp];
  _configuration = [[GIDConfiguration alloc] initWithClientID:kClientId
                                               serverClientID:kServerClientId
                                                 hostedDomain:kHostedDomain
                                                  openIDRealm:nil];
}

- (void)testCreateAuthorizationRequest_signInFlow {
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                       presentingViewController:nil
#elif TARGET_OS_OSX
                                               presentingWindow:nil
#endif // TARGET_OS_OSX
                                                      loginHint:kUserEmail
                                                  addScopesFlow:NO
                                                     completion:nil];
  OIDAuthorizationRequest *request =
      [GIDAuthorizationUtil authorizationRequestWithOptions:options
                                                 emmSupport:nil];
  
  NSDictionary<NSString *, NSObject *> *params = request.additionalParameters;
  XCTAssertEqualObjects(params[kIncludeGrantedScopesParameter], @"true");
  XCTAssertEqualObjects(params[kSDKVersionLoggingParameter], GIDVersion());
  XCTAssertEqualObjects(params[kEnvironmentLoggingParameter], GIDEnvironment());
  XCTAssertEqualObjects(params[kLoginHintParameter], kUserEmail, @"login hint should match");
  XCTAssertEqualObjects(params[kHostedDomainParameter], kHostedDomain,
                        @"hosted domain should match");
  XCTAssertEqualObjects(params[kAudienceParameter], kServerClientId, @"client ID should match");
  
  NSArray<NSString *> *defaultScopes = @[kScopeEmail, kScopeProfile];
  NSString *expectedScopeString = [defaultScopes componentsJoinedByString:@" "];
  XCTAssertEqualObjects(request.scope, expectedScopeString);
}

- (void)testCreateAuthorizationRequest_additionalScopes {
  NSArray<NSString *> *addtionalScopes = @[kScopeBirthday];
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                       presentingViewController:nil
#elif TARGET_OS_OSX
                                               presentingWindow:nil
#endif // TARGET_OS_OSX
                                                      loginHint:kUserEmail
                                                  addScopesFlow:NO
                                                         scopes:addtionalScopes
                                                     completion:nil];
  OIDAuthorizationRequest *request =
      [GIDAuthorizationUtil authorizationRequestWithOptions:options
                                                 emmSupport:nil];
  
  NSArray<NSString *> *expectedScopes = @[kScopeBirthday, kScopeEmail, kScopeProfile];
  NSString *expectedScopeString = [expectedScopes componentsJoinedByString:@" "];
  XCTAssertEqualObjects(request.scope, expectedScopeString);
}

- (void)testCreateAuthrizationRequest_addScopes {
  NSArray<NSString *> *scopes = @[kScopeEmail, kScopeProfile, kScopeBirthday];
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                       presentingViewController:nil
#elif TARGET_OS_OSX
                                               presentingWindow:nil
#endif // TARGET_OS_OSX
                                                      loginHint:kUserEmail
                                                  addScopesFlow:YES
                                                         scopes:scopes
                                                     completion:nil];
  
  OIDAuthorizationRequest *request =
      [GIDAuthorizationUtil authorizationRequestWithOptions:options
                                                 emmSupport:nil];
  
  NSString *expectedScopeString = [scopes componentsJoinedByString:@" "];
  XCTAssertEqualObjects(request.scope, expectedScopeString);
}

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (void)testCreateAuthorizationRequest_signInFlow_EMM {
  GIDSignInInternalOptions *options =
      [GIDSignInInternalOptions defaultOptionsWithConfiguration:_configuration
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
                                       presentingViewController:nil
#elif TARGET_OS_OSX
                                               presentingWindow:nil
#endif // TARGET_OS_OSX
                                                      loginHint:kUserEmail
                                                  addScopesFlow:NO
                                                     completion:nil];
  OIDAuthorizationRequest *request =
      [GIDAuthorizationUtil authorizationRequestWithOptions:options
                                                 emmSupport:kEMMVersion];
  
  NSString *systemName = [UIDevice currentDevice].systemName;
  if ([systemName isEqualToString:@"iPhone OS"]) {
    systemName = @"iOS";
  }
  NSString *expectedOSVersion = [NSString stringWithFormat:@"%@ %@",
      systemName, [UIDevice currentDevice].systemVersion];
  NSDictionary<NSString *, NSObject *> *authParams = request.additionalParameters;
  
  BOOL isEligibleForEMM = [UIDevice currentDevice].systemVersion.integerValue >= 9;
  if (isEligibleForEMM) {
    XCTAssertEqualObjects(authParams[@"emm_support"], kEMMVersion,
                          @"EMM support should match in auth request");
    XCTAssertEqualObjects(authParams[@"device_os"], expectedOSVersion,
                          @"OS version should match in auth request");
  } else {
    XCTAssertNil(authParams[@"emm_support"],
                 @"EMM support should not be in auth request for unsupported OS");
    XCTAssertNil(authParams[@"device_os"],
                 @"OS version should not be in auth request for unsupported OS");
  }
}

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (void)testUnionScopes_success {
  NSArray<NSString *> *scopes = @[kScopeEmail, kScopeProfile];
  NSArray<NSString *> *newScopes = @[kScopeBirthday];
  
  NSError *error;
  NSArray<NSString *> *allScopes =
      [GIDAuthorizationUtil resolvedScopesFromGrantedScoped:scopes
                                              withNewScopes:newScopes
                                                      error:&error];
  
  NSArray<NSString *> *expectedScopes = @[kScopeEmail, kScopeProfile, kScopeBirthday];
  XCTAssertEqualObjects(allScopes, expectedScopes);
  XCTAssertNil(error);
}

- (void)testUnionScopes_addExistingScopes_error {
  NSArray<NSString *> *scopes = @[kScopeEmail, kScopeProfile, kScopeBirthday];
  NSArray<NSString *> *newScopes = @[kScopeBirthday];
  
  NSError *error;
  NSArray<NSString *> *allScopes =
      [GIDAuthorizationUtil resolvedScopesFromGrantedScoped:scopes
                                              withNewScopes:newScopes
                                                      error:&error];
  
  XCTAssertNil(allScopes);
  XCTAssertEqualObjects(error.domain, kGIDSignInErrorDomain);
  XCTAssertEqual(error.code, kGIDSignInErrorCodeScopesAlreadyGranted);
}

@end

NS_ASSUME_NONNULL_END
