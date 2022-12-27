#import "GoogleSignIn/Sources/GIDHTTPFetcher/Implementations/Fakes/GIDFakeHTTPFetcher.h"

@interface GIDFakeHTTPFetcher ()

@property(nonatomic) GIDHTTPFetcherTestBlock testBlock;

@property(nonatomic) NSURL *requestURL;

@end

@implementation GIDFakeHTTPFetcher

- (void)fetchURLrequest:(NSURLRequest *)urlRequest
          fromAuthState:(OIDAuthState *)authState
            withComment:(NSString *)comment
             completion:(void (^)(NSData *_Nullable, NSError *_Nullable))completion {
  self.requestURL = urlRequest.URL;
  NSAssert(self.testBlock != nil, @"Set the test block before invoking this method.");
  self.testBlock(^(NSData *_Nullable data, NSError *_Nullable error){
    completion(data,error);
  });
}

@end
