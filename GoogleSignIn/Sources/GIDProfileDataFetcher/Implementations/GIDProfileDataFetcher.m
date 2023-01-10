/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

// Basic profile (Fat ID Token / userinfo endpoint) keys
static NSString *const kBasicProfileEmailKey = @"email";
static NSString *const kBasicProfilePictureKey = @"picture";
static NSString *const kBasicProfileNameKey = @"name";
static NSString *const kBasicProfileGivenNameKey = @"given_name";
static NSString *const kBasicProfileFamilyNameKey = @"family_name";

@implementation GIDProfileDataFetcher {
  id<GIDHTTPFetcher> _httpFetcher;
}

- (instancetype)init {
  GIDHTTPFetcher *httpFetcher = [[GIDHTTPFetcher alloc] init];
  return [self initWithHTTPFetcher:httpFetcher];
}

- (instancetype)initWithHTTPFetcher:(id<GIDHTTPFetcher>)httpFetcher {
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
  // If profile data is present in the ID token, use it.
  if (idToken) {
    GIDProfileData *profileData = [self fetchProfileDataWithIDToken:idToken];
    if (profileData) {
      completion(profileData, nil);
      return;
    }
  }
  
  // If we can't retrieve profile data from the ID token, make a UserInfo endpoint request to
  // fetch it.
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

- (nullable GIDProfileData*)fetchProfileDataWithIDToken:(OIDIDToken *)idToken {
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
