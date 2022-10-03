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

#import "GoogleSignIn/Sources/GIDAppAuthFetcherAuthorizationWithEMMSupport.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDToken_Private.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// The ID Token claim key for the hosted domain value.
static NSString *const kHostedDomainIDTokenClaimKey = @"hd";

// Key constants used for encode and decode.
static NSString *const kAuthenticationKey = @"authentication";
static NSString *const kProfileDataKey = @"profileData";
static NSString *const kAuthState = @"authState";

// Parameters for the token exchange endpoint.
static NSString *const kAudienceParameter = @"audience";
static NSString *const kOpenIDRealmParameter = @"openid.realm";

// Additional parameter names for EMM.
static NSString *const kEMMSupportParameterName = @"emm_support";

// Minimal time interval before expiration for the access token or it needs to be refreshed.
NSTimeInterval kMinimalTimeToExpire = 60.0;

@implementation GIDGoogleUser {
  OIDAuthState *_authState;
  GIDConfiguration *_cachedConfiguration;
  
  // A queue for pending refrsh token handlers so we don't fire multiple requests in parallel.
  // Access to this ivar should be synchronized.
  NSMutableArray *_refreshTokensHandlerQueue;
}

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

- (void)doWithFreshTokens:(GIDGoogleUserCompletion)completion {
  if (!([self.accessToken.expirationDate timeIntervalSinceNow] < kMinimalTimeToExpire ||
      (self.idToken && [self.idToken.expirationDate timeIntervalSinceNow] < kMinimalTimeToExpire))) {
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(self, nil);
    });
    return;
  }
  @synchronized (_refreshTokensHandlerQueue) {
    // Push the handler into the callback queue.
    [_refreshTokensHandlerQueue addObject:[completion copy]];
    if (_refreshTokensHandlerQueue.count > 1) {
      // This is not the first handler in the queue, no fetch is needed.
      return;
    }
  }
  // This is the first handler in the queue, a fetch is needed.
  NSMutableDictionary *additionalParameters = [@{} mutableCopy];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport updatedEMMParametersWithParameters:
          _authState.lastTokenResponse.request.additionalParameters]];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      _authState.lastTokenResponse.request.additionalParameters];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  additionalParameters[kSDKVersionLoggingParameter] = GIDVersion();
  additionalParameters[kEnvironmentLoggingParameter] = GIDEnvironment();

  OIDTokenRequest *tokenRefreshRequest =
      [_authState tokenRefreshRequestWithAdditionalParameters:additionalParameters];
  [OIDAuthorizationService performTokenRequest:tokenRefreshRequest
                 originalAuthorizationResponse:_authState.lastAuthorizationResponse
                                      callback:^(OIDTokenResponse *_Nullable tokenResponse,
                                                 NSError *_Nullable error) {
    if (tokenResponse) {
      [self->_authState updateWithTokenResponse:tokenResponse error:nil];
    } else {
      if (error.domain == OIDOAuthTokenErrorDomain) {
        [self->_authState updateWithAuthorizationError:error];
      }
    }
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    [GIDEMMSupport handleTokenFetchEMMError:error completion:^(NSError *_Nullable error) {
      // Process the handler queue to call back.
      NSArray *refreshTokensHandlerQueue;
      @synchronized(self->_refreshTokensHandlerQueue) {
        refreshTokensHandlerQueue = [self->_refreshTokensHandlerQueue copy];
        [self->_refreshTokensHandlerQueue removeAllObjects];
      }
      for (GIDGoogleUserCompletion completion in refreshTokensHandlerQueue) {
        dispatch_async(dispatch_get_main_queue(), ^{
          completion(error ? nil : self, error);
        });
      }
    }];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
    NSArray *refreshTokensHandlerQueue;
    @synchronized(self->_refreshTokensHandlerQueue) {
      refreshTokensHandlerQueue = [self->_refreshTokensHandlerQueue copy];
      [self->_refreshTokensHandlerQueue removeAllObjects];
    }
    for (GIDAuthenticationCompletion completion in refreshTokensHandlerQueue) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(error ? nil : self, error);
      });
    }
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  }];
}

#pragma mark - Private Methods

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (nullable NSString *)emmSupport {
  return
      _authState.lastAuthorizationResponse.request.additionalParameters[kEMMSupportParameterName];
}
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(nullable GIDProfileData *)profileData {
  self = [super init];
  if (self) {
    _refreshTokensHandlerQueue = [[NSMutableArray alloc] init];
    _authState = authState;
    _authState.stateChangeDelegate = self;
    _profile = profileData;
    
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    GTMAppAuthFetcherAuthorization *authorization = self.emmSupport ?
        [[GIDAppAuthFetcherAuthorizationWithEMMSupport alloc] initWithAuthState:_authState] :
        [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:_authState];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
    GTMAppAuthFetcherAuthorization *authorization =
        [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:_authState];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    authorization.tokenRefreshDelegate = self;
    self.fetcherAuthorizer = authorization;
    
    [self updateTokensWithAuthState:authState];
  }
  return self;
}

- (void)updateWithTokenResponse:(nullable OIDTokenResponse *)tokenResponse
                    profileData:(nullable GIDProfileData *)profileData {
  @synchronized(self) {
    _profile = profileData;
    if (tokenResponse) {
      [_authState updateWithTokenResponse:tokenResponse error:nil];
    }
  }
}

- (void)updateTokensWithAuthState:(OIDAuthState *)authState {
  GIDToken *accessToken =
      [[GIDToken alloc] initWithTokenString:authState.lastTokenResponse.accessToken
                             expirationDate:authState.lastTokenResponse.accessTokenExpirationDate];
  if (![self.accessToken isEqualToToken:accessToken]) {
    self.accessToken = accessToken;
  }
  
  GIDToken *refreshToken = [[GIDToken alloc] initWithTokenString:authState.refreshToken
                                                  expirationDate:nil];
  if (![self.refreshToken isEqualToToken:refreshToken]) {
    self.refreshToken = refreshToken;
  }
  
  GIDToken *idToken;
  NSString *idTokenString = authState.lastTokenResponse.idToken;
  if (idTokenString) {
    NSDate *idTokenExpirationDate =
        [[[OIDIDToken alloc] initWithIDTokenString:idTokenString] expiresAt];
    idToken = [[GIDToken alloc] initWithTokenString:idTokenString
                                     expirationDate:idTokenExpirationDate];
  } else {
    idToken = nil;
  }
  if ((self.idToken || idToken) && ![self.idToken isEqualToToken:idToken]) {
    self.idToken = idToken;
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

#pragma mark - GTMAppAuthFetcherAuthorizationTokenRefreshDelegate

- (nullable NSDictionary *)additionalRefreshParameters:
    (GTMAppAuthFetcherAuthorization *)authorization {
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  return [GIDEMMSupport updatedEMMParametersWithParameters:
      authorization.authState.lastTokenResponse.request.additionalParameters];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
  return authorization.authState.lastTokenResponse.request.additionalParameters;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
}

#pragma mark - OIDAuthStateChangeDelegate

- (void)didChangeState:(OIDAuthState *)state {
   [self updateTokensWithAuthState:state];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _refreshTokensHandlerQueue = [[NSMutableArray alloc] init];
    _profile = [decoder decodeObjectOfClass:[GIDProfileData class] forKey:kProfileDataKey];
    _authState = [decoder decodeObjectOfClass:[OIDAuthState class] forKey:kAuthState];
    _authState.stateChangeDelegate = self;
    
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    GTMAppAuthFetcherAuthorization *authorization = self.emmSupport ?
        [[GIDAppAuthFetcherAuthorizationWithEMMSupport alloc] initWithAuthState:_authState] :
        [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:_authState];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
    GTMAppAuthFetcherAuthorization *authorization =
        [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:_authState];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    authorization.tokenRefreshDelegate = self;
    self.fetcherAuthorizer = authorization;
    
    [self updateTokensWithAuthState:_authState];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_profile forKey:kProfileDataKey];
  [encoder encodeObject:_authState forKey:kAuthState];
}

@end

NS_ASSUME_NONNULL_END
