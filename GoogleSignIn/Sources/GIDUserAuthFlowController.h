#import <Foundation/Foundation.h>

@class OIDAuthState;
@class GIDProfileData;
@class GIDSignInInternalOptions;

NS_ASSUME_NONNULL_BEGIN

@interface GIDUserAuthFlowResult : NSObject

@property(nonatomic, readonly) OIDAuthState *authState;
@property(nonatomic, readonly) GIDProfileData *profileData;
@property(nonatomic, readonly, nullable) NSString *serverAuthCode;

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(GIDProfileData *)profileData
                   serverAuthCode:(nullable NSString *)serverAuthCode;

@end

typedef void (^GIDUserAuthFlowCompletion)(GIDUserAuthFlowResult *_Nullable result,
                                          NSError *_Nullable error);

@interface GIDUserAuthFlowController: NSObject

/// This method should be called from your `UIApplicationDelegate`'s `application:openURL:options:`
/// method.
///
/// @param url The URL that was passed to the app.
/// @return `YES` if `GIDSignIn` handled this URL.
- (BOOL)handleURL:(NSURL *)url;

- (void)signInWithOptions:(GIDSignInInternalOptions *)options
               completion:(GIDUserAuthFlowCompletion)completion;

- (void)authenticateInteractivelyWithOptions:(GIDSignInInternalOptions *)options
                                  completion:(GIDUserAuthFlowCompletion)completion;

- (void)authenticateNonInteractivelyWithOptions:(GIDSignInInternalOptions *)options
                                     completion:(GIDUserAuthFlowCompletion)completion

@end

NS_ASSUME_NONNULL_END
