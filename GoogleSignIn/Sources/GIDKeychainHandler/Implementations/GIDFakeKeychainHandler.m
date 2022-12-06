#import "GoogleSignIn/Sources/GIDKeychainHandler/Implementations/GIDFakeKeychainHandler.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GIDFakeKeychainHandler {
  OIDAuthState *_savedAuthState;
}

- (OIDAuthState *)loadAuthState {
  return _savedAuthState;
}

- (BOOL)saveAuthState:(OIDAuthState *)authState {
  if (self.failToSave) {
    _savedAuthState = nil;
    return NO;
  } else {
    _savedAuthState = authState;
    return YES;
  }
}

- (void)removeAllKeychainEntries {
  _savedAuthState = nil;
}

@end

NS_ASSUME_NONNULL_END
