#import <Foundation/Foundation.h>

@class OIDAuthState;
@class GIDProfileData;

NS_ASSUME_NONNULL_BEGIN

@interface GIDUserAuthFlowResult : NSObject

@property(nonatomic, readonly) OIDAuthState *authState;
@property(nonatomic, readonly) GIDProfileData *profileData;
@property(nonatomic, readonly, nullable) NSString *serverAuthCode;

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(GIDProfileData *)profileData
                   serverAuthCode:(nullable NSString *)serverAuthCode;

@end

NS_ASSUME_NONNULL_END
