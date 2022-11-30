#import "GoogleSignIn/Sources/GIDKeychainHandlling/GIDKeychainHandler.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#endif

// Keychain constants for saving state in the authentication flow.
static NSString *const kGTMAppAuthKeychainName = @"auth";

NS_ASSUME_NONNULL_BEGIN

@implementation GIDKeychainHandler


- (OIDAuthState *)loadAuthState {
  GTMAppAuthFetcherAuthorization *authorization =
      [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kGTMAppAuthKeychainName
                                             useDataProtectionKeychain:YES];
  return authorization.authState;
}

- (BOOL)saveAuthState:(OIDAuthState *)authState {
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
  return [GTMAppAuthFetcherAuthorization saveAuthorization:authorization
                                         toKeychainForName:kGTMAppAuthKeychainName
                                 useDataProtectionKeychain:YES];
}

- (void)removeAllKeychainEntries {
  [GTMAppAuthFetcherAuthorization removeAuthorizationFromKeychainForName:kGTMAppAuthKeychainName
                                               useDataProtectionKeychain:YES];
}

@end

NS_ASSUME_NONNULL_END
