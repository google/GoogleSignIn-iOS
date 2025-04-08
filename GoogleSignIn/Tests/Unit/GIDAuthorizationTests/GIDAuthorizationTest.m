//
//  GIDAuthorizationTest.m
//  GoogleSignIn
//
//  Created by Matt Mathias on 4/7/25.
//

#import <XCTest/XCTest.h>
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthorization.h"
#import "GoogleSignIn/Sources/GIDAuthorization_Private.h"
#import "GoogleSignIn/Tests/Unit/GIDConfiguration+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"

#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Implementations/Fake/GIDAuthorizationFlowFake.h"

@interface GIDAuthorizationTest : XCTestCase

@end

@implementation GIDAuthorizationTest

- (void)testAuthorizationConfigurationAssertValidParameters {
  GIDConfiguration *configuration =
    [[GIDConfiguration alloc] initWithClientID:OIDAuthorizationRequestTestingClientID
                                serverClientID:kServerClientID
                                  hostedDomain:kHostedDomain
                                   openIDRealm:kOpenIDRealm];
  GIDAuthorizationFlowFake *fakeFlow =
    [GIDAuthorizationFlowFake fakeWithDefaultOptionsConfiguration:configuration];
  GIDAuthorization *authorization =
    [[GIDAuthorization alloc] initWithKeychainStore:nil
                                      configuration:configuration
                       authorizationFlowCoordinator:fakeFlow];
  
  @try {
    [authorization assertValidParameters];
  }
  @catch (NSException *exception) {
    XCTFail(@"`authorization` should have valid parameters.");
  }
  @finally {}
}

- (void)testAuthorizationConfigurationAssertValidPresentingController {
  GIDAuthorizationFlowFake *fakeFlow = [GIDAuthorizationFlowFake fakeWithDefaultOptions];
  GIDAuthorization *authorization =
    [[GIDAuthorization alloc] initWithKeychainStore:nil
                                      configuration:nil
                       authorizationFlowCoordinator:fakeFlow];
  @try {
    [authorization assertValidPresentingController];
  }
  @catch (NSException *exception) {
    XCTFail(@"`authorization` should have a valid presenting controller.");
  }
  @finally {}
}

@end
