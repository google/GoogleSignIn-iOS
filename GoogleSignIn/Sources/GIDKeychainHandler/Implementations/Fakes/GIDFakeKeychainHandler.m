#import "GoogleSignIn/Sources/GIDKeychainHandler/Implementations/Fakes/GIDFakeKeychainHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface GIDFakeKeychainHandler ()

@property(nonatomic, nullable) OIDAuthState *savedAuthState;

@end

@implementation GIDFakeKeychainHandler

- (nullable OIDAuthState *)loadAuthState {
  return self.savedAuthState;
}

- (BOOL)saveAuthState:(OIDAuthState *)authState {
  if (self.failToSave) {
    self.savedAuthState = nil;
    return NO;
  } else {
    self.savedAuthState = authState;
    return YES;
  }
}

- (void)removeAllKeychainEntries {
  self.savedAuthState = nil;
}

@end

NS_ASSUME_NONNULL_END
