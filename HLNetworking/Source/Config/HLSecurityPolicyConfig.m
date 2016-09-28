//
//  HLSecurityPolicyConfig.m
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLSecurityPolicyConfig.h"

@interface HLSecurityPolicyConfig ()

@property (readwrite, nonatomic, assign) HLSSLPinningMode SSLPinningMode;

@end

@implementation HLSecurityPolicyConfig
+ (instancetype)policyWithPinningMode:(HLSSLPinningMode)pinningMode {
    HLSecurityPolicyConfig *securityPolicy = [[HLSecurityPolicyConfig alloc] init];
    if (securityPolicy) {
        securityPolicy.SSLPinningMode           = pinningMode;
        securityPolicy.allowInvalidCertificates = NO;
        securityPolicy.validatesDomainName      = YES;
    }
    return securityPolicy;
}
@end
