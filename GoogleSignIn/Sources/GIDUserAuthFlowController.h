#import <Foundation/Foundation.h>

@class OIDAuthState;
@class GIDProfileData;
@class GIDSignInInternalOptions;
@class GIDUserAuthFlowResult;

NS_ASSUME_NONNULL_BEGIN


typedef void (^GIDUserAuthFlowCompletion)(GIDUserAuthFlowResult *_Nullable result,
                                          NSError *_Nullable error);

@interface GIDUserAuthFlowController: NSObject

/// This method should be called from your `UIApplicationDelegate`'s `application:openURL:options:`
/// method.
///
/// @param url The URL that was passed to the app.
/// @return `YES` if `GIDSignIn` handled this URL.
- (BOOL)handleURL:(NSURL *)url;

- (void)authenticateInteractivelyWithOptions:(GIDSignInInternalOptions *)options
                                  completion:(GIDUserAuthFlowCompletion)completion;

- (void)authenticateNonInteractivelyWithOptions:(GIDSignInInternalOptions *)options
                                     completion:(GIDUserAuthFlowCompletion)completion;

@end

NS_ASSUME_NONNULL_END
