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

#import "GoogleSignIn/Tests/Unit/OIDTokenResponse+Testing.h"

#import "GoogleSignIn/Tests/Unit/OIDAuthorizationRequest+Testing.h"
#import "GoogleSignIn/Tests/Unit/OIDTokenRequest+Testing.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDScopeUtilities.h>
#import <AppAuth/OIDTokenRequest.h>
#import <AppAuth/OIDTokenResponse.h>
#endif

NSString *const kAccessToken = @"access_token";
NSTimeInterval const kAccessTokenExpiresIn = 3600;
NSString *const kRefreshToken = @"refresh_token";
NSString *const kServerAuthCode = @"server_auth_code";

// ID token constants
NSString *const kAlg = @"RS256";
NSString *const kKid = @"alkjdfas";
NSString *const kTyp = @"JWT";
NSString *const kUserID = @"12345679";
NSString *const kHostedDomain = @"fakehosteddomain.com";
NSString *const kIssuer = @"https://test.com";
NSString *const kAudience = @"audience";
NSTimeInterval const kIDTokenExpires = 1000;
NSTimeInterval const kIssuedAt = 0;

NSString *const kFatNameKey = @"name";
NSString *const kFatGivenNameKey = @"given_name";
NSString *const kFatFamilyNameKey = @"family_name";
NSString *const kFatPictureURLKey = @"picture";

NSString * const kFatName = @"fake username";
NSString * const kFatGivenName = @"fake";
NSString * const kFatFamilyName = @"username";
NSString * const kFatPictureURL = @"fake_user_picture_url";

@implementation OIDTokenResponse (Testing)

+ (instancetype)testInstance {
  return [self testInstanceWithIDToken:[self idToken]];
}

+ (instancetype)testInstanceWithIDToken:(NSString *)idToken {
  return [OIDTokenResponse testInstanceWithIDToken:idToken
                                       accessToken:nil
                                         expiresIn:nil
                                      refreshToken:nil
                                      tokenRequest:nil];
}

+ (instancetype)testInstanceWithIDToken:(NSString *)idToken
                            accessToken:(NSString *)accessToken
                              expiresIn:(NSNumber *)expiresIn
                           refreshToken:(NSString *)refreshToken
                           tokenRequest:(OIDTokenRequest *)tokenRequest {
  NSMutableDictionary<NSString *, NSString *> *parameters;
  parameters = [[NSMutableDictionary alloc] initWithDictionary:@{
    @"access_token" : accessToken ?: kAccessToken,
    @"expires_in" : expiresIn ?: @(kAccessTokenExpiresIn),
    @"token_type" : @"example_token_type",
    @"refresh_token" : refreshToken ?: kRefreshToken,
    @"scope" : [OIDScopeUtilities scopesWithArray:@[ OIDAuthorizationRequestTestingScope2 ]],
    @"server_code" : kServerAuthCode,
  }];
  if (idToken) {
    parameters[@"id_token"] = idToken;
  }
  return [[OIDTokenResponse alloc] initWithRequest:tokenRequest ?: [OIDTokenRequest testInstance]
                                        parameters:parameters];
}

+ (NSString *)idToken {
  return [self idTokenWithSub:kUserID exp:@(kIDTokenExpires) fat:NO];
}

+ (NSString *)fatIDToken {
  return [self idTokenWithSub:kUserID exp:@(kIDTokenExpires) fat:YES];
}

+ (NSString *)idTokenWithSub:(NSString *)sub exp:(NSNumber *)exp {
  return [self idTokenWithSub:sub exp:exp fat:NO];
}

+ (NSString *)idTokenWithSub:(NSString *)sub exp:(NSNumber *)exp fat:(BOOL)fat {
  NSError *error;
  NSDictionary *headerContents = @{
    @"alg" : kAlg,
    @"kid" : kKid,
    @"typ" : kTyp,
  };
  NSData *headerJson = [NSJSONSerialization dataWithJSONObject:headerContents
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
  if (error || !headerJson) {
    return nil;
  }
  NSMutableDictionary<NSString *, NSString *> *payloadContents =
      [NSMutableDictionary dictionaryWithDictionary:@{
    @"sub" : sub,
    @"hd"  : kHostedDomain,
    @"iss" : kIssuer,
    @"aud" : kAudience,
    @"exp" : exp,
    @"iat" : @(kIssuedAt),
  }];
  if (fat) {
    [payloadContents addEntriesFromDictionary:@{
      kFatNameKey : kFatName,
      kFatGivenNameKey : kFatGivenName,
      kFatFamilyNameKey : kFatFamilyName,
      kFatPictureURLKey : kFatPictureURL,
    }];
  }
  NSData *payloadJson = [NSJSONSerialization dataWithJSONObject:payloadContents
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:&error];
  if (error || !payloadJson) {
    return nil;
  }
  return [NSString stringWithFormat:@"%@.%@.FakeSignature",
          [headerJson base64EncodedStringWithOptions:0],
          [payloadJson base64EncodedStringWithOptions:0]];
}

@end
