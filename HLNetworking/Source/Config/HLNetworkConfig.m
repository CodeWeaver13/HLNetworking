//
//  HLNetworkConfig.m
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLNetworkConfig.h"

@implementation HLNetworkConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _tips = [HLNetworkTipsConfig config];
        _request = [HLNetworkRequestConfig config];
        _policy = [HLNetworkPolicyConfig config];
        _enableReachability = NO;
        _enableGlobalLog = NO;
        _defaultSecurityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:HLSSLPinningModeNone];
    }
    return self;
}

+ (HLNetworkConfig *)config {
    return [[self alloc] init];
}

- (id)copyWithZone:(NSZone *)zone {
    HLNetworkConfig *config = [[[self class] alloc] init];
    if (config) {
        config.tips = [_tips copyWithZone:zone];
        config.request = [_request copyWithZone:zone];
        config.policy = [_policy copyWithZone:zone];
        config.defaultSecurityPolicy = [_defaultSecurityPolicy copyWithZone:zone];
        config.enableReachability = _enableReachability;
        config.defaultSecurityPolicy = _defaultSecurityPolicy;
    }
    return config;
}
@end
