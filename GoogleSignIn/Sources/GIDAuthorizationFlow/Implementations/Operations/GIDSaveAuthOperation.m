//
//  GIDSaveAuthOperation.m
//  GoogleSignIn
//
//  Created by Matt Mathias on 4/3/25.
//

#import "GIDSaveAuthOperation.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"

#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Implementations/Operations/GIDDecodeIDTokenOperation.h"
#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"
#import "GoogleSignIn/Sources/GIDSignInInternalOptions.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <GTMAppAuth/GTMAuthSession>
#endif

@interface GIDSaveAuthOperation ()

@property(nonatomic, readwrite, nullable) NSError *error;
@property(nonatomic, readwrite, nullable) GIDGoogleUser *currentUser;

@end

@implementation GIDSaveAuthOperation

- (void)main {
  GIDDecodeIDTokenOperation *idToken = (GIDDecodeIDTokenOperation *)self.dependencies.firstObject;
  NSError *error = idToken.error;
  OIDAuthState *authState = idToken.authState;
  
  if (authState && !error) {
    if (![self saveAuthState:authState]) {
      self.error = [self errorWithString:kKeychainError code:kGIDSignInErrorCodeKeychain];
      return;
    }
    
    GIDProfileData *profileData = idToken.profileData;
    if (self.options.addScopesFlow) {
      [self.currentUser updateWithTokenResponse:authState.lastTokenResponse
                            authorizationResponse:authState.lastAuthorizationResponse
                                      profileData:profileData];
    } else {
      GIDGoogleUser *user = [[GIDGoogleUser alloc] initWithAuthState:authState
                                                         profileData:profileData];
      self.currentUser = user;
    }
  }
}

- (BOOL)saveAuthState:(OIDAuthState *)authState {
  GTMAuthSession *authorization = [[GTMAuthSession alloc] initWithAuthState:authState];
  NSError *error;
  GTMKeychainStore *keychainStore =
    [[GTMKeychainStore alloc] initWithItemName:kGTMAppAuthKeychainName];
  [keychainStore saveAuthSession:authorization error:&error];
  return error == nil;
}

// TODO: Extract this to an error class
- (NSError *)errorWithString:(NSString *)errorString code:(GIDSignInErrorCode)code {
  if (errorString == nil) {
    errorString = @"Unknown error";
  }
  NSDictionary<NSString *, NSString *> *errorDict = @{ NSLocalizedDescriptionKey : errorString };
  return [NSError errorWithDomain:kGIDSignInErrorDomain
                             code:code
                         userInfo:errorDict];
}

@end
