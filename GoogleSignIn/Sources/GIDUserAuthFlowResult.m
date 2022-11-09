#import "GoogleSignIn/Sources/GIDUserAuthFlowResult.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

@implementation GIDUserAuthFlowResult

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(GIDProfileData *)profileData
                   serverAuthCode:(nullable NSString *)serverAuthCode{
  self = [super init];
  if (self) {
    _authState = authState;
    _profileData = profileData;
    _serverAuthCode = [serverAuthCode copy];
  }
  return self;
};

@end
