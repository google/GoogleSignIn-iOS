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

// Additional parameter names for EMM.
static NSString *const kEMMSupportParameterName = @"emm_support";

NS_ASSUME_NONNULL_BEGIN

// A specialized GTMAppAuthFetcherAuthorization subclass with EMM support.
@interface GTMAppAuthFetcherAuthorizationWithEMMSupport : GTMAppAuthFetcherAuthorization
@end

@interface GIDGoogleUser ()

@property(nonatomic, readwrite) GIDToken *accessToken;

@property(nonatomic, readwrite) GIDToken *refreshToken;

@property(nonatomic, readwrite, nullable) GIDToken *idToken;

@end

@implementation GIDGoogleUser {
  OIDAuthState *_authState;
  GIDConfiguration *_cachedConfiguration;
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (id<GTMFetcherAuthorizationProtocol>)fetcherAuthorizer {
#pragma clang diagnostic pop
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  GTMAppAuthFetcherAuthorization *authorization = self.emmSupport ?
      [[GTMAppAuthFetcherAuthorizationWithEMMSupport alloc] initWithAuthState:_authState] :
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:_authState];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:_authState];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  authorization.tokenRefreshDelegate = self;
  return authorization;
}

#pragma mark - Private Methods

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (NSString *)emmSupport {
  return
      _authState.lastAuthorizationResponse.request.additionalParameters[kEMMSupportParameterName];
}
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

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
    
    [self updateTokensWithAuthState:authState];
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
  return [GIDAuthentication updatedEMMParametersWithParameters:
      authorization.authState.lastTokenResponse.request.additionalParameters];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
  return authorization.authState.lastTokenResponse.request.additionalParameters;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#pragma mark - GTMAppAuthFetcherAuthorizationEMMChainedDelegate

// The specialized GTMAppAuthFetcherAuthorization delegate that handles potential EMM error
// responses.
@interface GTMAppAuthFetcherAuthorizationEMMChainedDelegate : NSObject

// Initializes with chained delegate and selector.
- (instancetype)initWithDelegate:(id)delegate selector:(SEL)selector;

// The callback method for GTMAppAuthFetcherAuthorization to invoke.
- (void)authentication:(GTMAppAuthFetcherAuthorization *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(nullable NSError *)error;

@end

@implementation GTMAppAuthFetcherAuthorizationEMMChainedDelegate {
  // We use a weak reference here to match GTMAppAuthFetcherAuthorization.
  __weak id _delegate;
  SEL _selector;
  // We need to maintain a reference to the chained delegate because GTMAppAuthFetcherAuthorization
  // only keeps a weak reference.
  GTMAppAuthFetcherAuthorizationEMMChainedDelegate *_retained_self;
}

- (instancetype)initWithDelegate:(id)delegate selector:(SEL)selector {
  self = [super init];
  if (self) {
    _delegate = delegate;
    _selector = selector;
    _retained_self = self;
  }
  return self;
}

- (void)authentication:(GTMAppAuthFetcherAuthorization *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(nullable NSError *)error {
  [GIDAuthentication handleTokenFetchEMMError:error completion:^(NSError *_Nullable error) {
    if (!self->_delegate || !self->_selector) {
      return;
    }
    NSMethodSignature *signature = [self->_delegate methodSignatureForSelector:self->_selector];
    if (!signature) {
      return;
    }
    id argument1 = auth;
    id argument2 = request;
    id argument3 = error;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self->_delegate];  // index 0
    [invocation setSelector:self->_selector];  // index 1
    [invocation setArgument:&argument1 atIndex:2];
    [invocation setArgument:&argument2 atIndex:3];
    [invocation setArgument:&argument3 atIndex:4];
    [invocation invoke];
  }];
  // Prepare to deallocate the chained delegate instance because the above block will retain the
  // iVar references it uses.
  _retained_self = nil;
}

@end

#pragma mark - GTMAppAuthFetcherAuthorizationWithEMMSupport

@implementation GTMAppAuthFetcherAuthorizationWithEMMSupport

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)authorizeRequest:(nullable NSMutableURLRequest *)request
                delegate:(id)delegate
       didFinishSelector:(SEL)sel {
#pragma clang diagnostic pop
  GTMAppAuthFetcherAuthorizationEMMChainedDelegate *chainedDelegate =
      [[GTMAppAuthFetcherAuthorizationEMMChainedDelegate alloc] initWithDelegate:delegate
                                                                        selector:sel];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [super authorizeRequest:request
                 delegate:chainedDelegate
        didFinishSelector:@selector(authentication:request:finishedWithError:)];
#pragma clang diagnostic pop
}

- (void)authorizeRequest:(nullable NSMutableURLRequest *)request
       completionHandler:(GTMAppAuthFetcherAuthorizationCompletion)handler {
  [super authorizeRequest:request completionHandler:^(NSError *_Nullable error) {
    [GIDAuthentication handleTokenFetchEMMError:error completion:^(NSError *_Nullable error) {
      handler(error);
    }];
  }];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_END
