//
//  GIDAuthorizationCompletionOperation.h
//  GoogleSignIn
//
//  Created by Matt Mathias on 4/3/25.
//

#import <Foundation/Foundation.h>

@class GIDAuthorizationFlow;

NS_ASSUME_NONNULL_BEGIN

@interface GIDAuthorizationCompletionOperation : NSOperation

- (instancetype)initWithAuthorizationFlow:(GIDAuthorizationFlow *)authFlow;

@end

NS_ASSUME_NONNULL_END
