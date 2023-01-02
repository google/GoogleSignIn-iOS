#import "GoogleSignIn/Sources/GIDProfileDataFetcher/Implementations/GIDProfileDataFetcher.h"

#import "GoogleSignIn/Sources/GIDHTTPFetcher/API/GIDHTTPFetcher.h"
#import "GoogleSignIn/Sources/GIDHTTPFetcher/Implementations/GIDHTTPFetcher.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// The URL template for the URL to get user info.
static NSString *const kUserInfoURLTemplate = @"https://%@/oauth2/v3/userinfo";

@implementation GIDProfileDataFetcher {
  id<GIDHTTPFetcher> _httpFetcher;
}

- (instancetype)init {
  GIDHTTPFetcher *httpFetcher = [[GIDHTTPFetcher alloc] init];
  return [self initWithDataFetcher:httpFetcher];
}

- (instancetype)initWithDataFetcher:(id<GIDHTTPFetcher>)httpFetcher {
  self = [super init];
  if (self) {
    _httpFetcher = httpFetcher;
  }
  return self;
}

- (void)fetchProfileDataWithAuthState:(OIDAuthState *)authState
                           completion:(void (^)(GIDProfileData *_Nullable profileData,
                                                NSError *_Nullable error))completion {
  OIDIDToken *idToken =
      [[OIDIDToken alloc] initWithIDTokenString:authState.lastTokenResponse.idToken];
  // If the profile data are present in the ID token, use them.
  if (idToken) {
    GIDProfileData *profileData = [[GIDProfileData alloc] initWithIDToken:idToken];
    completion(profileData, nil);
    return;
  }
  
  // If we can't retrieve profile data from the ID token, make a userInfo request to fetch them.
  NSString *infoString = [NSString stringWithFormat:kUserInfoURLTemplate,
                             [GIDSignInPreferences googleUserInfoServer]];
  NSURL *infoURL = [NSURL URLWithString:infoString];
  NSMutableURLRequest *infoRequest = [NSMutableURLRequest requestWithURL:infoURL];
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
  
  [_httpFetcher fetchURLRequest:infoRequest
                 withAuthorizer:authorization
                    withComment:@"GIDSignIn: fetch basic profile info"
                     completion:^(NSData *data, NSError *error) {
    if (error) {
      completion(nil, error);
      return;
    }
    NSError *jsonDeserializationError;
    NSDictionary<NSString *, NSString *> *profileDict =
        [NSJSONSerialization JSONObjectWithData:data
                                        options:NSJSONReadingMutableContainers
                                          error:&jsonDeserializationError];
    if (jsonDeserializationError) {
      completion(nil, jsonDeserializationError);
      return;
    }
    GIDProfileData *profileData = [[GIDProfileData alloc]
        initWithEmail:idToken.claims[kBasicProfileEmailKey]
                 name:profileDict[kBasicProfileNameKey]
            givenName:profileDict[kBasicProfileGivenNameKey]
           familyName:profileDict[kBasicProfileFamilyNameKey]
             imageURL:[NSURL URLWithString:profileDict[kBasicProfilePictureKey]]];
    completion(profileData, nil);
  }];
}

@end

NS_ASSUME_NONNULL_END
