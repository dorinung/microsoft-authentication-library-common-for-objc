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
#import "MSIDJsonSerializable.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIDTestAutomationAccount : NSObject <MSIDJsonSerializable>

@property (nonatomic, readonly) NSString *objectId;
@property (nonatomic, readonly) NSString *userType;
@property (nonatomic, readonly) NSString *upn;
@property (nonatomic, readonly) NSString *domainUsername;
@property (nonatomic, readonly) NSString *keyvaultName;
@property (nonatomic, readonly) NSString *homeObjectId;
@property (nonatomic, readonly) NSString *targetTenantId;
@property (nonatomic, readonly) NSString *homeTenantId;
@property (nonatomic, readonly) NSString *tenantName;
@property (nonatomic, readonly) NSString *homeTenantName;
@property (nonatomic, readonly) NSString *homeAccountId;
@property (nonatomic, readonly) BOOL isHomeAccount;

// Writable properties
@property (nonatomic, nullable) NSString *password;
@property (nonatomic, nullable) NSString *overriddenTargetTenantId;
@property (nonatomic, nullable) NSString *overriddenKeyvaultName;

@property (nonatomic, nullable, readonly) NSString *associatedAppID;

@end

NS_ASSUME_NONNULL_END
