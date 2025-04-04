//
//  GIDDecodeIDTokenOperation.h
//  GoogleSignIn
//
//  Created by Matt Mathias on 4/3/25.
//

#import <Foundation/Foundation.h>

@class GIDProfileData;
@class GIDSignInInternalOptions;
@class OIDAuthState;

NS_ASSUME_NONNULL_BEGIN

@interface GIDDecodeIDTokenOperation : NSOperation

@property(nonatomic, readonly, nullable) GIDProfileData *profileData;
@property(nonatomic, readonly, nullable) NSError *error;
@property(nonatomic, readonly, nullable) OIDAuthState *authState;
@property(nonatomic, readonly, nullable) GIDSignInInternalOptions *options;

@end

NS_ASSUME_NONNULL_END
