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

#import "MSIDSilentController+Internal.h"
#import "MSIDSilentTokenRequest.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryAPIEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDTokenResult.h"
#import "MSIDAccount.h"
#if TARGET_OS_IPHONE
#import "MSIDBackgroundTaskManager.h"
#endif

@interface MSIDSilentController()

@property (nonatomic, readwrite) BOOL forceRefresh;
@property (nonatomic) MSIDSilentTokenRequest *currentRequest;

@end

@implementation MSIDSilentController

#pragma mark - Init

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDRequestParameters *)parameters
                                      forceRefresh:(BOOL)forceRefresh
                              tokenRequestProvider:(id<MSIDTokenRequestProviding>)tokenRequestProvider
                                             error:(NSError * _Nullable * _Nullable)error
{
    return [self initWithRequestParameters:parameters
                              forceRefresh:forceRefresh
                      tokenRequestProvider:tokenRequestProvider
             fallbackInteractiveController:nil
                                     error:error];
}

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDRequestParameters *)parameters
                                      forceRefresh:(BOOL)forceRefresh
                              tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                     fallbackInteractiveController:(nullable id<MSIDRequestControlling>)fallbackController
                                             error:(NSError * _Nullable * _Nullable)error
{
    self = [super initWithRequestParameters:parameters
                       tokenRequestProvider:tokenRequestProvider
                         fallbackController:fallbackController
                                      error:error];
    
    if (self)
    {
        _forceRefresh = forceRefresh;
    }
    
    return self;
}

#pragma mark - MSIDRequestControlling

- (void)acquireToken:(nonnull MSIDRequestCompletionBlock)completionBlock
{
#if TARGET_OS_IPHONE
    [[MSIDBackgroundTaskManager sharedInstance] startOperationWithType:MSIDBackgroundTaskTypeSilentRequest];
#endif
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Beginning silent flow.");
    
    MSIDRequestCompletionBlock completionBlockWrapper = ^(MSIDTokenResult * _Nullable result, NSError * _Nullable error)
    {
#if TARGET_OS_IPHONE
    [[MSIDBackgroundTaskManager sharedInstance] stopOperationWithType:MSIDBackgroundTaskTypeSilentRequest];
#endif
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Silent flow finished. Result %@, error: %ld error domain: %@", _PII_NULLIFY(result), (long)error.code, error.domain);
        completionBlock(result, error);
    };
    
    __auto_type request = [self.tokenRequestProvider silentTokenRequestWithParameters:self.requestParameters
                                                                         forceRefresh:self.forceRefresh];
    request.skipLocalRt = self.fallbackController != nil;
    [self acquireTokenWithRequest:request completionBlock:completionBlockWrapper];
}

#pragma mark - Protected

- (void)acquireTokenWithRequest:(MSIDSilentTokenRequest *)request
                completionBlock:(MSIDRequestCompletionBlock)completionBlock
{
    if (!completionBlock)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Passed nil completionBlock");
        return;
    }

    CONDITIONAL_START_EVENT(CONDITIONAL_SHARED_INSTANCE, self.requestParameters.telemetryRequestId, MSID_TELEMETRY_EVENT_API_EVENT);
    self.currentRequest = request;
    [request executeRequestWithCompletion:^(MSIDTokenResult *result, NSError *error)
    {
        if (result || !self.fallbackController)
        {
#if !EXCLUDE_FROM_MSALCPP
            [self addTelemetryEvent:result isSsoExtFallBack:YES error:error];
#endif
            self.currentRequest = nil;
            completionBlock(result, error);
            return;
        }

        MSIDRequestCompletionBlock completionBlockWrapper = ^(MSIDTokenResult *ssoResult, NSError *ssoError)
        {
            // We don't have any meaningful information from fallback controller (edge case of SSO error) so we use the local controller result earlier
            
            // If ssoError presented already, skip broker when came back from local RT fallback
            if (!ssoResult && (self.requestParameters.allowGettingAccessTokenWithRefreshToken || ssoError.code == MSIDErrorSSOExtensionUnexpectedError))
            {
                // Skip duplicate local cache lookups
                request.forceRefresh = YES;
                request.skipLocalRt = NO;
                [request executeRequestWithCompletion:^(MSIDTokenResult *localRtResults, NSError *localRtError)
                {
#if !EXCLUDE_FROM_MSALCPP
                    [self addTelemetryEvent:localRtResults isSsoExtFallBack:YES error:localRtError];
#endif
                    self.currentRequest = nil;
                    [self completionHandler:localRtResults
                                  ssoResult:nil
                                      error:localRtError
                                   ssoError:ssoError
                            completionBlock:completionBlock];
                }];
                return;
            }
            
            self.currentRequest = nil;
            [self completionHandler:nil
                          ssoResult:ssoResult
                              error:error
                           ssoError:ssoError
                    completionBlock:completionBlock];
        };

        [self.fallbackController acquireToken:completionBlockWrapper];
    }];
}

#if !EXCLUDE_FROM_MSALCPP
- (void)addTelemetryEvent:(MSIDTokenResult *)result
         isSsoExtFallBack:(BOOL)isSsoExtFallBack
                    error:(NSError *)error
{
    MSIDTelemetryAPIEvent *telemetryEvent = [self telemetryAPIEvent];
    [telemetryEvent setUserInformation:result.account];
    [telemetryEvent setIsExtendedLifeTimeToken:result.extendedLifeTimeToken ? MSID_TELEMETRY_VALUE_YES : MSID_TELEMETRY_VALUE_NO];
    if(isSsoExtFallBack)
    {
        [telemetryEvent setSsoExtFallBackFlow:1];
    }
    
    [self stopTelemetryEvent:telemetryEvent error:error];
}
#endif

- (void)completionHandler:(nullable MSIDTokenResult *)result
                ssoResult:(nullable MSIDTokenResult *)ssoResult
                    error:(nullable NSError *)error
                 ssoError:(nullable NSError *)ssoError
          completionBlock:(nonnull MSIDRequestCompletionBlock)completionBlock
{
    if (result)
    {
        completionBlock(result, error);
    }
    else if (!ssoResult && (ssoError.code == MSIDErrorSSOExtensionUnexpectedError))
    {
        completionBlock(result, error);
    }
    else
    {
        completionBlock(ssoResult, ssoError);
    }
}

@end
