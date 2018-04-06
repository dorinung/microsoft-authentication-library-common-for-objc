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

#import "MSIDTestCacheAccessor.h"
#import "MSIDError.h"
#import "MSIDAccount.h"
#import "MSIDAccessToken.h"
#import "MSIDRefreshToken.h"
#import "MSIDRequestParameters.h"
#import "MSIDOauth2Strategy.h"

@interface MSIDTestCacheAccessor()
{
    NSMutableDictionary *_cacheContents;
}

@end

@implementation MSIDTestCacheAccessor

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _cacheContents = [NSMutableDictionary dictionary];
    }
    
    return self;
}


- (BOOL)saveTokensWithStrategy:(MSIDOauth2Strategy *)strategy
                 requestParams:(MSIDRequestParameters *)parameters
                       account:(MSIDAccount *)account
                      response:(MSIDTokenResponse *)response
                       context:(id<MSIDRequestContext>)context
                         error:(NSError **)error
{
    if (!parameters)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return NO;
    }
    
    MSIDAccessToken *accessToken = [strategy accessTokenFromResponse:response request:parameters];
    
    return [self saveTokenForAccount:account token:accessToken clientId:parameters.clientId authority:parameters.authority context:context error:error];
}

- (BOOL)saveRefreshToken:(MSIDRefreshToken *)refreshToken
                 account:(MSIDAccount *)account
                 context:(id<MSIDRequestContext>)context
                   error:(NSError **)error
{
    return [self saveTokenForAccount:account token:refreshToken clientId:refreshToken.clientId authority:refreshToken.authority context:context error:error];
}


- (MSIDBaseToken *)getTokenWithType:(MSIDTokenType)tokenType
                            account:(MSIDAccount *)account
                      requestParams:(MSIDRequestParameters *)parameters
                            context:(id<MSIDRequestContext>)context
                              error:(NSError **)error
{
    return [self getTokenForAccount:account
                          tokenType:tokenType
                           clientId:parameters.clientId
                          authority:parameters.authority
                            context:context
                              error:error];
}

- (MSIDBaseToken *)getLatestToken:(MSIDBaseToken *)token
                          account:(MSIDAccount *)account
                          context:(id<MSIDRequestContext>)context
                            error:(NSError **)error
{
    return [self getTokenForAccount:account
                          tokenType:MSIDTokenTypeRefreshToken
                           clientId:token.clientId
                          authority:token.authority
                            context:context
                              error:error];
}

- (BOOL)removeToken:(MSIDBaseToken *)token
            account:(MSIDAccount *)account
            context:(id<MSIDRequestContext>)context
              error:(NSError **)error
{
    if (!account
        || !token)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return NO;
    }
    
    NSString *tokenIdentifier = [self tokenIdentifierForAccount:account
                                                      tokenType:token.tokenType
                                                       clientId:token.clientId
                                                      authority:token.authority];
    
    NSMutableArray *accountTokens = nil;
    
    @synchronized (self) {
        accountTokens = _cacheContents[tokenIdentifier];
        
        if (accountTokens)
        {
            [accountTokens removeObject:token];
        }
    }
    
    return YES;
}

- (NSArray *)getAllTokensOfType:(MSIDTokenType)tokenType
                   withClientId:(NSString *)clientId
                        context:(id<MSIDRequestContext>)context
                          error:(NSError **)error
{
    if (!clientId)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing clientId", nil, nil, nil, nil, nil);
        }
        
        return nil;
    }
    
    NSMutableArray *resultTokens = [NSMutableArray array];
    
    @synchronized (self) {
        
        // Filter out tokens based on the clientId
        for (NSString *key in [_cacheContents allKeys])
        {
            NSArray *contents = _cacheContents[key];
            
            for (MSIDBaseToken *token in contents)
            {
                if (token.tokenType == tokenType
                    && [token.clientId isEqualToString:clientId])
                {
                    [resultTokens addObject:token];
                }
            }
        }
    }
    
    return  resultTokens;
}

- (NSArray<MSIDTokenCacheItem *> *)allItemsWithContext:(id<MSIDRequestContext>)context
                                                 error:(NSError **)error
{
    return nil;
}

- (NSArray<MSIDAccount *> *)getAllAccountsWithContext:(id<MSIDRequestContext>)context error:(NSError *__autoreleasing *)error
{
    return nil;
}

- (BOOL)removeAccount:(MSIDAccount *)account context:(id<MSIDRequestContext>)context error:(NSError *__autoreleasing *)error
{
    return NO;
}

- (BOOL)removeAllTokensForAccount:(MSIDAccount *)account context:(id<MSIDRequestContext>)context error:(NSError *__autoreleasing *)error
{
    return NO;
}

#pragma mark - Helpers

- (BOOL)saveTokenForAccount:(MSIDAccount *)account
                      token:(MSIDBaseToken *)token
                   clientId:(NSString *)clientId
                  authority:(NSURL *)authority
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    if (!token
        || !account)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return NO;
    }
    
    if ((self.requireLegacyUserId && !account.legacyUserId)
        || (self.requireDefaultUserId && !account.uniqueUserId))
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return NO;
    }
    
    NSString *tokenIdentifier = [self tokenIdentifierForAccount:account tokenType:token.tokenType clientId:clientId authority:authority];
    
    NSMutableArray *accountTokens = nil;
    
    @synchronized (self) {
        accountTokens = _cacheContents[tokenIdentifier];
    }
    
    if (!accountTokens)
    {
        accountTokens = [NSMutableArray array];
    }
    
    [accountTokens addObject:token];
    
    @synchronized (self) {
        _cacheContents[tokenIdentifier] = accountTokens;
    }
    
    return YES;
}

- (MSIDBaseToken *)getTokenForAccount:(MSIDAccount *)account
                            tokenType:(MSIDTokenType)tokenType
                             clientId:(NSString *)clientId
                            authority:(NSURL *)authority
                           context:(id<MSIDRequestContext>)context
                                error:(NSError **)error
{
    if (!clientId
        || !authority)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing parameter", nil, nil, nil, nil, nil);
        }
        
        return nil;
    }
    
    NSString *tokenIdentifier = [self tokenIdentifierForAccount:account tokenType:tokenType clientId:clientId authority:authority];
    
    NSMutableArray *accountTokens = nil;
    
    @synchronized (self) {
        accountTokens = _cacheContents[tokenIdentifier];
    }
    
    if (!accountTokens || ![accountTokens count])
    {
        return nil;
    }
    
    return accountTokens[0];
}

- (NSString *)tokenIdentifierForAccount:(MSIDAccount *)account
                              tokenType:(MSIDTokenType)tokenType
                               clientId:(NSString *)clientId
                              authority:(NSURL *)authority
{
    NSString *userIdentifier = account.uniqueUserId ? account.uniqueUserId : account.legacyUserId;
    
    NSString *cloudIdentifier = tokenType == MSIDTokenTypeRefreshToken ? authority.msidHostWithPortIfNecessary : authority.absoluteString;
    
    return [NSString stringWithFormat:@"%@_%@_%@_%@", userIdentifier, [self tokenTypeAsString:tokenType], clientId, cloudIdentifier];
}

- (NSString *)tokenTypeAsString:(MSIDTokenType)tokenType
{
    NSString *typeIdentifier = @"at";
    
    if (tokenType == MSIDTokenTypeRefreshToken)
    {
        typeIdentifier = @"rt";
    }
    
    return typeIdentifier;
}

#pragma mark - Test Utils

- (void)addToken:(MSIDBaseToken *)token forAccount:(MSIDAccount *)account
{
    NSString *clientId = token.clientId;
    
    if (token.tokenType == MSIDTokenTypeRefreshToken)
    {
        MSIDRefreshToken *refreshToken = (MSIDRefreshToken *)token;
        NSString *familyId = [NSString stringWithFormat:@"foci-%@", refreshToken.familyId];
        clientId = [NSString msidIsStringNilOrBlank:refreshToken.familyId] ? token.clientId : familyId;
    }
    
    [self saveTokenForAccount:account token:token clientId:clientId authority:token.authority context:nil error:nil];
}

- (void)reset
{
    @synchronized (self) {
        _cacheContents = [NSMutableDictionary dictionary];
    }
}

- (NSArray *)allAccessTokens
{
    return [self allTokensWithType:MSIDTokenTypeAccessToken clientId:nil];
}

- (NSArray *)allRefreshTokens
{
    return [self allTokensWithType:MSIDTokenTypeRefreshToken clientId:nil];
}

- (NSArray *)allMRRTTokensWithClientId:(NSString *)clientId
{
    return [self allTokensWithType:MSIDTokenTypeRefreshToken clientId:clientId];
}

- (NSArray *)allFRTTokensWithFamilyId:(NSString *)familyId
{
    return [self allMRRTTokensWithClientId:[NSString stringWithFormat:@"foci-%@", familyId]];
}

- (NSArray *)allTokensWithType:(MSIDTokenType)type clientId:(NSString *)clientId
{
    NSMutableArray *resultTokens = [NSMutableArray array];
    
    @synchronized (self) {
       
        // Filter out tokens based on the token type
        for (NSString *key in [_cacheContents allKeys])
        {
            if ([key containsString:[self tokenTypeAsString:type]]
                && (!clientId || [key containsString:clientId])
                && _cacheContents[key])
            {
                if (clientId)
                {
                    for (MSIDBaseToken *token in _cacheContents[key])
                    {
                        if ([token.clientId isEqualToString:clientId])
                        {
                            [resultTokens addObject:token];
                        }
                    }
                }
                else
                {
                    [resultTokens addObjectsFromArray:_cacheContents[key]];
                }
            }
        }
        
    }
    
    return resultTokens;
}

@end
