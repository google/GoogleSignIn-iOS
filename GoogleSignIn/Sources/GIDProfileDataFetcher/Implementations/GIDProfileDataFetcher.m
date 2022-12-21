#import "GoogleSignIn/Sources/GIDProfileDataFetcher/Implementations/GIDProfileDataFetcher.h"

#import "GoogleSignIn/Sources/GIDDataFetcher/API/GIDDataFetcher.h"
#import "GoogleSignIn/Sources/GIDDataFetcher/Implementations/GIDDataFetcher.h"
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
static NSString *const kUserInfoURLTemplate = @"https://%@/oauth2/v3/userinfo?access_token=%@";

// Maximum retry interval in seconds for the fetcher.
static const NSTimeInterval kFetcherMaxRetryInterval = 15.0;

// Basic profile (Fat ID Token / userinfo endpoint) keys
static NSString *const kBasicProfileEmailKey = @"email";
static NSString *const kBasicProfilePictureKey = @"picture";
static NSString *const kBasicProfileNameKey = @"name";
static NSString *const kBasicProfileGivenNameKey = @"given_name";
static NSString *const kBasicProfileFamilyNameKey = @"family_name";

@implementation GIDProfileDataFetcher {
  id<GIDDataFetcher> _dataFetcher;
}

- (instancetype)init {
  GIDDataFetcher *dataFetcher = [[GIDDataFetcher alloc] init];
  return [self initWithDataFetcher:dataFetcher];
}

- (instancetype)initWithDataFetcher: (id<GIDDataFetcher>)dataFetcher {
  self = [super init];
  if (self) {
    _dataFetcher = dataFetcher;
  }
  return self;
}

- (void)fetchProfileDataWithAuthState:(OIDAuthState *)authState
                           completion:(void (^)(GIDProfileData *_Nullable profileData,
                                                NSError *_Nullable error))completion {
  OIDIDToken *idToken =
      [[OIDIDToken alloc] initWithIDTokenString: authState.lastTokenResponse.idToken];
  // If the profile data are present in the ID token, use them.
  if (idToken) {
    GIDProfileData *profileData = [self profileDataWithIDToken:idToken];
    completion(profileData, nil);
    return;
  }
  // If we can't retrieve profile data from the ID token, make a userInfo request to fetch them.
  NSURL *infoURL = [NSURL URLWithString:
      [NSString stringWithFormat:kUserInfoURLTemplate,
          [GIDSignInPreferences googleUserInfoServer],
          authState.lastTokenResponse.accessToken]];
  [_dataFetcher fetchURL:infoURL
             withComment:@"GIDSignIn: fetch basic profile info"
              completion:^(NSData *data, NSError *error) {
    if (error) {
      completion(nil, error);
    } else {
      NSError *jsonDeserializationError;
      NSDictionary<NSString *, NSString *> *profileDict =
        [NSJSONSerialization JSONObjectWithData:data
                                        options:NSJSONReadingMutableContainers
                                          error:&jsonDeserializationError];
      if (profileDict) {
        GIDProfileData *profileData = [[GIDProfileData alloc]
            initWithEmail:idToken.claims[kBasicProfileEmailKey]
                     name:profileDict[kBasicProfileNameKey]
                givenName:profileDict[kBasicProfileGivenNameKey]
               familyName:profileDict[kBasicProfileFamilyNameKey]
                 imageURL:[NSURL URLWithString:profileDict[kBasicProfilePictureKey]]];
        completion(profileData, nil);
      }
      else {
        completion(nil, jsonDeserializationError);
      }
    }
  }];
}

// Generates user profile from OIDIDToken.
- (GIDProfileData *)profileDataWithIDToken:(OIDIDToken *)idToken {
  if (!idToken ||
      !idToken.claims[kBasicProfilePictureKey] ||
      !idToken.claims[kBasicProfileNameKey] ||
      !idToken.claims[kBasicProfileGivenNameKey] ||
      !idToken.claims[kBasicProfileFamilyNameKey]) {
    return nil;
  }

  return [[GIDProfileData alloc]
      initWithEmail:idToken.claims[kBasicProfileEmailKey]
               name:idToken.claims[kBasicProfileNameKey]
          givenName:idToken.claims[kBasicProfileGivenNameKey]
          familyName:idToken.claims[kBasicProfileFamilyNameKey]
            imageURL:[NSURL URLWithString:idToken.claims[kBasicProfilePictureKey]]];
}

@end

NS_ASSUME_NONNULL_END
