#import "GoogleSignIn/Sources/GIDDataFetcher/Implementations/GIDDataFetcher.h"

#ifdef SWIFT_PACKAGE
@import GTMAppAuth;
#else
#import <GTMAppAuth/GTMAppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// Maximum retry interval in seconds for the fetcher.
static const NSTimeInterval kFetcherMaxRetryInterval = 15.0;

@implementation GIDDataFetcher

- (void)fetchURL:(NSURL *)URL
     withComment:(NSString *)comment
      completion:(void (^)(NSData *_Nullable, NSError *_Nullable))completion {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
  GTMSessionFetcher *fetcher = [GTMSessionFetcher fetcherWithRequest:request];
  fetcher.retryEnabled = YES;
  fetcher.maxRetryInterval = kFetcherMaxRetryInterval;
  fetcher.comment = comment;
  [fetcher beginFetchWithCompletionHandler:completion];
}

@end

NS_ASSUME_NONNULL_END
