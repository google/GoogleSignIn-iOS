#import "GoogleSignIn/Sources/GIDHTTPFetcher/Implementations/GIDHTTPFetcher.h"

#ifdef SWIFT_PACKAGE
@import GTMAppAuth;
#else
#import <GTMAppAuth/GTMAppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// Maximum retry interval in seconds for the fetcher.
static const NSTimeInterval kFetcherMaxRetryInterval = 15.0;

@implementation GIDHTTPFetcher

- (void)fetchURLrequest:(NSURLRequest *)urlRequest
          fromAuthState:(OIDAuthState *)authState
            withComment:(NSString *)comment
             completion:(void (^)(NSData *_Nullable, NSError *_Nullable))completion {
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
  GTMSessionFetcher *fetcher = [GTMSessionFetcher fetcherWithRequest:urlRequest];
  fetcher.authorizer = authorization;
  fetcher.retryEnabled = YES;
  fetcher.maxRetryInterval = kFetcherMaxRetryInterval;
  fetcher.comment = comment;
  [fetcher beginFetchWithCompletionHandler:completion];
}

@end

NS_ASSUME_NONNULL_END
