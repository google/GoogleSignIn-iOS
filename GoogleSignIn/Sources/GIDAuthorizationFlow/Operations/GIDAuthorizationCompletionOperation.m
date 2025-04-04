//
//  GIDAuthorizationCompletionOperation.m
//  GoogleSignIn
//
//  Created by Matt Mathias on 4/3/25.
//

#import "GIDAuthorizationCompletionOperation.h"

#import "GoogleSignIn/Sources/GIDSignIn_Private.h"
#import "GoogleSignIn/Sources/GIDSignInResult_Private.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Operations/GIDSaveAuthOperation.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"
#import "GoogleSignIn/Sources/GIDAuthorizationFlow/GIDAuthorizationFlow.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <GTMAppAuth/GTMAuthSession>
#endif

@interface GIDAuthorizationCompletionOperation ()

@property(nonatomic, nullable) GIDAuthorizationFlow *authFlow;

@end

@implementation GIDAuthorizationCompletionOperation

- (id)initWithAuthorizationFlow:(GIDAuthorizationFlow *)authFlow {
  self = [super init];
  if (self) {
    _authFlow = authFlow;
  }
  return self;
}

- (void)main {
  GIDSaveAuthOperation *saveAuth = (GIDSaveAuthOperation *)self.dependencies.firstObject;
  GIDSignInInternalOptions *options = saveAuth.options;
  
  if (options.completion) {
    GIDSignInCompletion completion = options.completion;
    self.authFlow.options = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
      if (saveAuth.error) {
        completion(nil, saveAuth.error);
      } else {
        OIDAuthState *authState = saveAuth.authState;
        NSString *_Nullable serverAuthCode =
          [authState.lastTokenResponse.additionalParameters[@"server_code"] copy];
        GIDSignInResult *signInResult =
          [[GIDSignInResult alloc] initWithGoogleUser:saveAuth.currentUser
                                       serverAuthCode:serverAuthCode];
        completion(signInResult, nil);
      }
    });
  }
}

@end
