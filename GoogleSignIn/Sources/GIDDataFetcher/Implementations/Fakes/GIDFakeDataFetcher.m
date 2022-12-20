#import "GoogleSignIn/Sources/GIDDataFetcher/Implementations/Fakes/GIDFakeDataFetcher.h"

@interface GIDFakeDataFetcher ()

@property(nonatomic) GIDDataFetcherTestBlock testBlock;

@property(nonatomic) NSURL *requestURL;

@end

@implementation GIDFakeDataFetcher

- (void)fetchURL:(NSURL *)URL
     withComment:(NSString *)comment
      completion:(void (^)(NSData *_Nullable, NSError *_Nullable))completion {
  self.requestURL = URL;
  NSAssert(self.testBlock != nil, @"Set the test block before invoking this method.");
  self.testBlock(^(NSData *_Nullable data, NSError *_Nullable error){
    completion(data,error);
  });
}

@end
