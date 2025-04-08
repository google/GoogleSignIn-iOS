//
//  GIDAuthorizationTest.m
//  GoogleSignIn
//
//  Created by Matt Mathias on 4/7/25.
//

#import <XCTest/XCTest.h>
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDAuthorization.h"
#import "GoogleSignIn/Sources/GIDAuthorization_Private.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Tests/Unit/GIDConfiguration+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"

#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Implementations/Fake/GIDAuthorizationFlowFake.h"

@interface GIDAuthorizationTest : XCTestCase

@end

@implementation GIDAuthorizationTest

- (void)testAuthorizationConfigurationAssertValidParameters {
  GIDConfiguration *config =
    [[GIDConfiguration alloc] initWithClientID:OIDAuthorizationRequestTestingClientID
                                serverClientID:kServerClientID
                                  hostedDomain:kHostedDomain
                                   openIDRealm:kOpenIDRealm];
  
  GIDSignInInternalOptions *opts = [GIDSignInInternalOptions defaultOptionsWithConfiguration:config
                                                                    presentingViewController:nil
                                                                                   loginHint:nil
                                                                               addScopesFlow:NO
                                                                                  completion:nil];
  GIDAuthorizationFlowFake *fakeFlow = [[GIDAuthorizationFlowFake alloc] initWithSignInOptions:opts
                                                                                     authState:nil
                                                                                   profileData:nil
                                                                                    googleUser:nil
                                                                      externalUserAgentSession:nil
                                                                                    emmSupport:nil
                                                                                         error:nil];
  @try {
    GIDAuthorization *authorization = [[GIDAuthorization alloc] initWithKeychainStore:nil
                                                                        configuration:config
                                                         authorizationFlowCoordinator:fakeFlow];
    [authorization assertValidParameters];
  }
  @catch (NSException *exception) {
    XCTFail(@"`authorization` should have valid parameters.");
  }
  @finally {}
}

- (void)testAuthorizationConfigurationAssertValidPresentingController {
  
  UIViewController *vc = [[UIViewController alloc] init];
  GIDSignInInternalOptions *opts = [GIDSignInInternalOptions defaultOptionsWithConfiguration:nil
                                                                    presentingViewController:vc
                                                                                   loginHint:nil
                                                                               addScopesFlow:NO
                                                                                  completion:nil];
  GIDAuthorizationFlowFake *fakeFlow = [[GIDAuthorizationFlowFake alloc] initWithSignInOptions:opts
                                                                                     authState:nil
                                                                                   profileData:nil
                                                                                    googleUser:nil
                                                                      externalUserAgentSession:nil
                                                                                    emmSupport:nil
                                                                                         error:nil];
  @try {
    GIDAuthorization *authorization = [[GIDAuthorization alloc] initWithKeychainStore:nil
                                                                        configuration:nil
                                                         authorizationFlowCoordinator:fakeFlow];
    [authorization assertValidPresentingController];
  }
  @catch (NSException *exception) {
    XCTFail(@"`authorization` should have a valid presenting controller.");
  }
  @finally {}
}

@end
