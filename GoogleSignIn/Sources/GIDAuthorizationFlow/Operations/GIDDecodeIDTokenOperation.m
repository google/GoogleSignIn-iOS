//
//  GIDDecodeIDTokenOperation.m
//  GoogleSignIn
//
//  Created by Matt Mathias on 4/3/25.
//

#import "GIDDecodeIDTokenOperation.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"

#import "GoogleSignIn/Sources/GIDAuthorizationFlow/Operations/GIDTokenFetchOperation.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"
#import "GoogleSignIn/Sources/GIDSignInConstants.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/OIDAuthState.h>
#import <GTMAppAuth/GTMAuthSession>
#endif

@interface GIDDecodeIDTokenOperation ()

@property(nonatomic, readwrite, nullable) GIDProfileData *profileData;
@property(nonatomic, readwrite, nullable) NSError *error;

@end

@implementation GIDDecodeIDTokenOperation

- (void)main {
  GIDTokenFetchOperation *tokenFetch = (GIDTokenFetchOperation *)self.dependencies.firstObject;
  OIDAuthState *authState = tokenFetch.authState;
  NSError *maybeError = tokenFetch.error;
  
  if (!authState || maybeError) {
    return;
  }
  OIDIDToken *idToken =
    [[OIDIDToken alloc] initWithIDTokenString: authState.lastTokenResponse.idToken];
  // If the profile data are present in the ID token, use them.
  if (idToken) {
    self.profileData = [self profileDataWithIDToken:idToken];
  }
  
  // If we can't retrieve profile data from the ID token, make a userInfo request to fetch them.
  if (self.profileData) {
    NSURL *infoURL = [NSURL URLWithString:
                      [NSString stringWithFormat:kUserInfoURLTemplate,
                       [GIDSignInPreferences googleUserInfoServer],
                       authState.lastTokenResponse.accessToken]];
    [self startFetchURL:infoURL
          fromAuthState:authState
            withComment:@"GIDSignIn: fetch basic profile info"
  withCompletionHandler:^(NSData *data, NSError *error) {
      if (data && !error) {
        NSError *jsonDeserializationError;
        NSDictionary<NSString *, NSString *> *profileDict =
        [NSJSONSerialization JSONObjectWithData:data
                                        options:NSJSONReadingMutableContainers
                                          error:&jsonDeserializationError];
        if (profileDict) {
          self.profileData = [[GIDProfileData alloc]
                               initWithEmail:idToken.claims[kBasicProfileEmailKey]
                                        name:profileDict[kBasicProfileNameKey]
                                   givenName:profileDict[kBasicProfileGivenNameKey]
                                  familyName:profileDict[kBasicProfileFamilyNameKey]
                                    imageURL:[NSURL URLWithString:profileDict[kBasicProfilePictureKey]]];
        }
      }
      if (error) {
        self.error = error;
      }
    }];
  }
}

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

- (void)startFetchURL:(NSURL *)URL
            fromAuthState:(OIDAuthState *)authState
              withComment:(NSString *)comment
    withCompletionHandler:(void (^)(NSData *, NSError *))handler {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
  GTMSessionFetcher *fetcher;
  GTMAuthSession *authorization = [[GTMAuthSession alloc] initWithAuthState:authState];
  id<GTMSessionFetcherServiceProtocol> fetcherService = authorization.fetcherService;
  if (fetcherService) {
    fetcher = [fetcherService fetcherWithRequest:request];
  } else {
    fetcher = [GTMSessionFetcher fetcherWithRequest:request];
  }
  fetcher.retryEnabled = YES;
  fetcher.maxRetryInterval = kFetcherMaxRetryInterval;
  fetcher.comment = comment;
  [fetcher beginFetchWithCompletionHandler:handler];
}

@end
