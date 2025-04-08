//
//  GIDSaveAuthOperation.h
//  GoogleSignIn
//
//  Created by Matt Mathias on 4/3/25.
//

#import <Foundation/Foundation.h>

@class GIDProfileData;
@class OIDAuthState;
@class GIDSignInInternalOptions;
@class GIDGoogleUser;

NS_ASSUME_NONNULL_BEGIN

@interface GIDSaveAuthOperation : NSOperation

@property(nonatomic, readonly, nullable) GIDProfileData *profileData;
@property(nonatomic, readonly, nullable) NSError *error;
@property(nonatomic, readonly, nullable) OIDAuthState *authState;
@property(nonatomic, readonly, nullable) GIDSignInInternalOptions *options;
@property(nonatomic, readonly, nullable) GIDGoogleUser *currentUser;

@end

NS_ASSUME_NONNULL_END
