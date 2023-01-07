#import "GoogleSignIn/Sources/GIDAuthorizationFlowProcessor/Implementations/Fakes/GIDFakeAuthorizationFlowProcessor.h"

@interface GIDFakeAuthorizationFlowProcessor ()

@property(nonatomic) GIDAuthorizationFlowProcessorTestBlock testBlock;

@end

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

/// Not used in test for now.
- (BOOL)isStarted {
  return YES;
}

/// Not used in test for now.
- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)url {
  return YES;
}

/// Not used in test for now.
- (void)cancelAuthenticationFlow {}

@end
