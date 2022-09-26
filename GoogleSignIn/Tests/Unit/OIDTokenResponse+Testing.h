/*
 * Copyright 2021 Google LLC
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

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/OIDTokenResponse.h>
#endif

extern NSString *const kAccessToken;
extern NSTimeInterval const kAccessTokenExpiresIn;
extern NSString *const kRefreshToken;
extern NSString *const kServerAuthCode;

// ID token constants
extern NSString *const kAlg;
extern NSString *const kKid;
extern NSString *const kTyp;
extern NSString *const kUserID;
extern NSString *const kHostedDomain;
extern NSString *const kIssuer;
extern NSString *const kAudience;
extern NSTimeInterval const kIDTokenExpires;
extern NSTimeInterval const kIssuedAt;

extern NSString *const kFatNameKey;
extern NSString *const kFatGivenNameKey;
extern NSString *const kFatFamilyNameKey;
extern NSString *const kFatPictureURLKey;

extern NSString * const kFatName;
extern NSString * const kFatGivenName;
extern NSString * const kFatFamilyName;
extern NSString * const kFatPictureURL;


@interface OIDTokenResponse (Testing)

+ (instancetype)testInstance;

+ (instancetype)testInstanceWithIDToken:(NSString *)idToken;

+ (instancetype)testInstanceWithIDToken:(NSString *)idToken
                            accessToken:(NSString *)accessToken
                              expiresIn:(NSNumber *)expiresIn
                           refreshToken:(NSString *)refreshToken
                           tokenRequest:(OIDTokenRequest *)tokenRequest;

+ (NSString *)idToken;

+ (NSString *)fatIDToken;

/**
 * @sub The subject of the ID token.
 * @exp The interval between 00:00:00 UTC on 1 January 1970 and the expiration date of the ID token.
 */
+ (NSString *)idTokenWithSub:(NSString *)sub exp:(NSNumber *)exp;

+ (NSString *)idTokenWithSub:(NSString *)sub exp:(NSNumber *)exp fat:(BOOL)fat;

@end
