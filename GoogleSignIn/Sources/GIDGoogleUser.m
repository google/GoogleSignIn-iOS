// Copyright 2021 Google LLC
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

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"

#import "GoogleSignIn/Sources/GIDAuthentication_Private.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"

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

@implementation GIDGoogleUser {
  OIDAuthState *_authState;
}

- (nullable NSString *)userID {
  NSString *idToken = [self idToken];
  if (idToken) {
    OIDIDToken *idTokenDecoded = [[OIDIDToken alloc] initWithIDTokenString:idToken];
    if (idTokenDecoded && idTokenDecoded.subject) {
      return [idTokenDecoded.subject copy];
    }
  }

  return nil;
}

- (nullable NSString *)hostedDomain {
  NSString *idToken = [self idToken];
  if (idToken) {
    OIDIDToken *idTokenDecoded = [[OIDIDToken alloc] initWithIDTokenString:idToken];
    if (idTokenDecoded && idTokenDecoded.claims[kHostedDomainIDTokenClaimKey]) {
      return [idTokenDecoded.claims[kHostedDomainIDTokenClaimKey] copy];
    }
  }

  return nil;
}

- (nullable NSString *)serverAuthCode {
  return [_authState.lastTokenResponse.additionalParameters[@"server_code"] copy];
}

- (nullable NSString *)serverClientID {
  return [_authState.lastTokenResponse.request.additionalParameters[kAudienceParameter] copy];
}

- (nullable NSString *)openIDRealm {
  return [_authState.lastTokenResponse.request.additionalParameters[kOpenIDRealmParameter] copy];
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
  _authState = authState;
  _authentication = [[GIDAuthentication alloc] initWithAuthState:authState];
  _profile = profileData;
}

#pragma mark - Helpers

- (NSString *)idToken {
  return _authState ? _authState.lastTokenResponse.idToken : nil;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _profile = [decoder decodeObjectOfClass:[GIDProfileData class] forKey:kProfileDataKey];
    if ([decoder containsValueForKey:kAuthState]) { // Current encoding
      _authState = [decoder decodeObjectOfClass:[OIDAuthState class] forKey:kAuthState];
    } else { // Old encoding
      GIDAuthentication *authentication = [decoder decodeObjectOfClass:[GIDAuthentication class]
                                                                forKey:kAuthenticationKey];
      _authState = authentication.authState;
    }
    _authentication = [[GIDAuthentication alloc] initWithAuthState:_authState];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_profile forKey:kProfileDataKey];
  [encoder encodeObject:_authState forKey:kAuthState];
}

@end

NS_ASSUME_NONNULL_END
