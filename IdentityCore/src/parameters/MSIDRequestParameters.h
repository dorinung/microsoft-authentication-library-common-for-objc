// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "MSIDRequestContext.h"
#import "MSIDCacheAccessor.h"

@class MSIDAuthority;
@class MSIDAccountIdentifier;
@class MSIDOauth2Factory;
@class MSIDTokenResponseValidator;
@class MSIDConfiguration;

@interface MSIDRequestParameters : NSObject <MSIDRequestContext>

@property (nonatomic) MSIDAuthority *authority;
@property (nonatomic) MSIDAuthority *cloudAuthority;
@property (nonatomic) NSString *redirectUri;
@property (nonatomic) NSString *clientId;
@property (nonatomic) NSString *target;
@property (nonatomic) NSString *oidcScope;
@property (nonatomic) MSIDAccountIdentifier *accountIdentifier;
@property (nonatomic) NSString *username;
@property (nonatomic) BOOL validateAuthority;
@property (nonatomic) NSDictionary *sliceParameters;
@property (nonatomic) NSUInteger tokenExpirationBuffer;
@property (nonatomic) BOOL extendedLifetimeEnabled;

#pragma mark MSIDRequestContext properties
@property (nonatomic) NSUUID *correlationId;
@property (nonatomic) NSString *logComponent;
@property (nonatomic) NSString *telemetryRequestId;
@property (nonatomic) NSDictionary *appRequestMetadata;
@property (nonatomic) NSString *telemetryApiId;

#pragma mark Conditional access
@property (nonatomic) NSDictionary *claims;
@property (nonatomic) NSArray *clientCapabilities;

#pragma mark Configuration
@property (nonatomic) MSIDConfiguration *msidConfiguration; // TODO: this one is not necessary, MSIDConfiguration should be replaced with MSIDRequestParams or vice versa

#pragma mark - Cache
// TODO: should this be moved somewhere else?
@property (nonatomic) NSString *keychainAccessGroup;

- (NSURL *)tokenEndpoint;

#pragma mark Methods
- (void)setCloudAuthorityWithCloudHostName:(NSString *)cloudHostName;
- (BOOL)setClaimsFromJSON:(NSString *)claims error:(NSError **)error;
- (NSString *)allTokenRequestScopes;

- (BOOL)validateParametersWithError:(NSError **)error;

@end
