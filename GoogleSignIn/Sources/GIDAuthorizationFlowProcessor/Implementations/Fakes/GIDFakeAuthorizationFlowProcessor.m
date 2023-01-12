#import "GoogleSignIn/Sources/GIDAuthorizationFlowProcessor/Implementations/Fakes/GIDFakeAuthorizationFlowProcessor.h"

@implementation GIDFakeAuthorizationFlowProcessor

- (void)startWithOptions:(GIDSignInInternalOptions *)options
              emmSupport:(nullable NSString *)emmSupport
              completion:(void (^)(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                   NSError *_Nullable error))completion {
  NSAssert(self.testBlock != nil, @"Set the test block before invoking this method.");
  
  
  self.testBlock(^(OIDAuthorizationResponse *authorizationResponse, NSError *error) {
    completion(authorizationResponse, error);
  });
}

- (BOOL)isStarted {
  NSAssert(NO, @"Not implemented.");
  return YES;
}

- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)url {
  NSAssert(NO, @"Not implemented.");
  return YES;
}

- (void)cancelAuthenticationFlow {
  NSAssert(NO, @"Not implemented.");
}

@end
