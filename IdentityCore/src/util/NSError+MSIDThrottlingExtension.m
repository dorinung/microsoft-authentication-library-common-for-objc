//
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


#import "NSError+MSIDThrottlingExtension.h"
#import "NSError+MSIDExtensions.h"

@implementation NSError (MSIDThrottlingExtension)

- (NSDate *)msidGetRetryDateFromError
{
    if (!self) return nil;
    NSDate *retryHeaderDate = nil;
    retryHeaderDate = [NSDate msidDateFromRetryHeader:[self msidGetHTTPHeaderValue:@"Retry-After"]];
    return retryHeaderDate;
}

- (BOOL)msidIsMSIDError
{
    if (!self) return NO;
    return [self.domain hasPrefix:@"MSID"];
}

- (NSString *)msidGetHTTPHeaderValue:(NSString *)headerKey
{
    if (!self) return nil;
    NSDictionary *headerFields = [self.domain hasPrefix:@"MSID"] ? self.userInfo[MSIDHTTPHeadersKey] : self.userInfo[@"MSALHTTPHeadersKey"];
    return headerFields[headerKey];
}

- (NSString *)msidGetUserInfoValueWithMSIDKey:(NSString *)msidKey
                                    orMSALKey:(NSString *)msalKey
{
    if (!self) return nil;
    return self.userInfo[[self msidIsMSIDError] ? msidKey : msalKey];
}

@end
