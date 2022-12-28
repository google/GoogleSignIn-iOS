#import "GoogleSignIn/Sources/GIDHTTPFetcher/Implementations/Fakes/GIDFakeHTTPFetcher.h"

@interface GIDFakeHTTPFetcher ()

@property(nonatomic) GIDHTTPFetcherTestBlock testBlock;

@end

@implementation GIDFakeHTTPFetcher

- (void)fetchURLRequest:(NSURLRequest *)urlRequest
         withAuthorizer:(id<GTMFetcherAuthorizationProtocol>)authorizer
            withComment:(NSString *)comment
             completion:(void (^)(NSData *_Nullable, NSError *_Nullable))completion {
  NSAssert(self.testBlock != nil, @"Set the test block before invoking this method.");
  self.testBlock(urlRequest, ^(NSData *_Nullable data, NSError *_Nullable error) {
    completion(data, error);
  });
}

@end
