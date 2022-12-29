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

- (void)fetchURLRequest:(NSURLRequest *)urlRequest
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
         withAuthorizer:(id<GTMFetcherAuthorizationProtocol>)authorizer
#pragma clang diagnostic pop
            withComment:(NSString *)comment
             completion:(void (^)(NSData *_Nullable, NSError *_Nullable))completion {
  GTMSessionFetcher *fetcher = [GTMSessionFetcher fetcherWithRequest:urlRequest];
  fetcher.authorizer = authorizer;
  fetcher.retryEnabled = YES;
  fetcher.maxRetryInterval = kFetcherMaxRetryInterval;
  fetcher.comment = comment;
  [fetcher beginFetchWithCompletionHandler:completion];
}

@end

NS_ASSUME_NONNULL_END
