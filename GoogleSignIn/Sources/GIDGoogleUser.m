// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

#import "GoogleSignIn/Sources/GIDAuthentication_Private.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"
#import "GoogleSignIn/Sources/GIDToken_Private.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

// The ID Token claim key for the hosted domain value.
static NSString *const kHostedDomainIDTokenClaimKey = @"hd";

// Key constants used for encode and decode.
static NSString *const kAuthenticationKey = @"authentication";
static NSString *const kProfileDataKey = @"profileData";
static NSString *const kAuthState = @"authState";

// Parameters for the token exchange endpoint.
static NSString *const kAudienceParameter = @"audience";
static NSString *const kOpenIDRealmParameter = @"openid.realm";

NS_ASSUME_NONNULL_BEGIN

@implementation GIDGoogleUser {
  OIDAuthState *_authState;
  GIDConfiguration *_cachedConfiguration;
}

@synthesize accessToken = _accessToken;
@synthesize refreshToken = _refreshToken;
@synthesize idToken = _idToken;

- (nullable NSString *)userID {
  NSString *idTokenString = self.idToken.tokenString;
  if (idTokenString) {
    OIDIDToken *idTokenDecoded =
        [[OIDIDToken alloc] initWithIDTokenString:idTokenString];
    if (idTokenDecoded && idTokenDecoded.subject) {
      return [idTokenDecoded.subject copy];
    }
  }

  return nil;
}

- (nullable NSArray<NSString *> *)grantedScopes {
  NSArray<NSString *> *grantedScopes;
  NSString *grantedScopeString = _authState.lastTokenResponse.scope;
  if (grantedScopeString) {
    // If we have a 'scope' parameter from the backend, this is authoritative.
    // Remove leading and trailing whitespace.
    grantedScopeString = [grantedScopeString stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceCharacterSet]];
    // Tokenize with space as a delimiter.
    NSMutableArray<NSString *> *parsedScopes =
        [[grantedScopeString componentsSeparatedByString:@" "] mutableCopy];
    // Remove empty strings.
    [parsedScopes removeObject:@""];
    grantedScopes = [parsedScopes copy];
  }
  return grantedScopes;
}

- (GIDConfiguration *)configuration {
  @synchronized(self) {
    // Caches the configuration since it would not change for one GIDGoogleUser instance.
    if (!_cachedConfiguration) {
      NSString *clientID = _authState.lastAuthorizationResponse.request.clientID;
      NSString *serverClientID =
          _authState.lastTokenResponse.request.additionalParameters[kAudienceParameter];
      NSString *openIDRealm =
          _authState.lastTokenResponse.request.additionalParameters[kOpenIDRealmParameter];
      
      _cachedConfiguration = [[GIDConfiguration alloc] initWithClientID:clientID
                                                         serverClientID:serverClientID
                                                           hostedDomain:[self hostedDomain]
                                                            openIDRealm:openIDRealm];
    };
  }
  
  return _cachedConfiguration;
}

#pragma mark - Private Methods

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(nullable GIDProfileData *)profileData {
  self = [super init];
  if (self) {
    [self updateAuthState:authState profileData:profileData];
  }
  return self;
}

- (void)updateAuthState:(OIDAuthState *)authState
            profileData:(nullable GIDProfileData *)profileData {
  @synchronized(self) {
    _authState = authState;
    _authentication = [[GIDAuthentication alloc] initWithAuthState:authState];
    _profile = profileData;
    
    [self sendKVONotificationsBeforeChanges];
    [self updateTokensWithAuthState:authState];
    [self sendKVONotificationAfterChanges];
  }
}

- (void)updateTokensWithAuthState:(OIDAuthState *)authState {
  _accessToken = [[GIDToken alloc] initWithTokenString:authState.lastTokenResponse.accessToken
                                        expirationDate:authState.lastTokenResponse.
                                                         accessTokenExpirationDate];
  _refreshToken = [[GIDToken alloc] initWithTokenString:authState.refreshToken
                                         expirationDate:nil];
  _idToken = nil;
  NSString *idTokenString = authState.lastTokenResponse.idToken;
  if (idTokenString) {
    NSDate *idTokenExpirationDate = [[[OIDIDToken alloc]
                                      initWithIDTokenString:idTokenString] expiresAt];
    _idToken = [[GIDToken alloc] initWithTokenString:idTokenString
                                      expirationDate:idTokenExpirationDate];
  }
}

#pragma mark - Helpers

- (nullable NSString *)hostedDomain {
  NSString *idTokenString = self.idToken.tokenString;
  if (idTokenString) {
    OIDIDToken *idTokenDecoded = [[OIDIDToken alloc] initWithIDTokenString:idTokenString];
    if (idTokenDecoded && idTokenDecoded.claims[kHostedDomainIDTokenClaimKey]) {
      return idTokenDecoded.claims[kHostedDomainIDTokenClaimKey];
    }
  }
  return nil;
}

- (void)sendKVONotificationsBeforeChanges {
  [self willChangeValueForKey:NSStringFromSelector(@selector(accessToken))];
  [self willChangeValueForKey:NSStringFromSelector(@selector(refreshToken))];
  [self willChangeValueForKey:NSStringFromSelector(@selector(idToken))];
}

- (void)sendKVONotificationAfterChanges {
  [self didChangeValueForKey:NSStringFromSelector(@selector(accessToken))];
  [self didChangeValueForKey:NSStringFromSelector(@selector(refreshToken))];
  [self didChangeValueForKey:NSStringFromSelector(@selector(idToken))];
}



#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    GIDProfileData *profileData =
        [decoder decodeObjectOfClass:[GIDProfileData class] forKey:kProfileDataKey];
    OIDAuthState *authState;
    if ([decoder containsValueForKey:kAuthState]) { // Current encoding
      authState = [decoder decodeObjectOfClass:[OIDAuthState class] forKey:kAuthState];
    } else { // Old encoding
      GIDAuthentication *authentication = [decoder decodeObjectOfClass:[GIDAuthentication class]
                                                                forKey:kAuthenticationKey];
      authState = authentication.authState;
    }
    [self updateAuthState:authState profileData:profileData];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_profile forKey:kProfileDataKey];
  [encoder encodeObject:_authState forKey:kAuthState];
}

@end

NS_ASSUME_NONNULL_END
