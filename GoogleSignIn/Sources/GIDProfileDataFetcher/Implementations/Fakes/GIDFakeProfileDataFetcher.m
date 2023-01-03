#import "GoogleSignIn/Sources/GIDProfileDataFetcher/Implementations/Fakes/GIDFakeProfileDataFetcher.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface GIDFakeProfileDataFetcher ()

@property(nonatomic) GIDProfileDataFetcherTestBlock testBlock;

@end

@implementation GIDFakeProfileDataFetcher

- (void)fetchProfileDataWithAuthState:(OIDAuthState *)authState
                           completion:(void (^)(GIDProfileData *_Nullable profileData,
                                                NSError *_Nullable error))completion {
  NSAssert(self.testBlock != nil, @"Set the test block before invoking this method.");
  self.testBlock(^(GIDProfileData *_Nullable profileData, NSError *_Nullable error){
    completion(profileData,error);
  });
}

@end

NS_ASSUME_NONNULL_END
