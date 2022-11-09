#import <Foundation/Foundation.h>

@class OIDAuthState;
@class GIDUserAuthFlowCompletion;

NS_ASSUME_NONNULL_BEGIN

@interface GIDUserFlowHelper : NSObject

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                       emmSupport:(NSString *)emmSupport;

- (instancetype)initWithError:(NSError *)error;

- (void)maybeFetchToken;

- (void)finishUserAuthFlowWithCompletion:(GIDUserAuthFlowCompletion)completion;

@end

NS_ASSUME_NONNULL_END
