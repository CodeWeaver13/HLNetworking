//
//  HLNetworkPolicyConfig.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLNetworkPolicyConfig.h"

@implementation HLNetworkPolicyConfig

+ (HLNetworkPolicyConfig *)config {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isBackgroundSession = NO;
        _isErrorCodeDisplayEnabled = YES;
        _cachePolicy = NSURLRequestUseProtocolCachePolicy;
        _URLCache = [NSURLCache sharedURLCache];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    HLNetworkPolicyConfig *config = [[[self class] alloc] init];
    if (config) {
        config.isErrorCodeDisplayEnabled = _isErrorCodeDisplayEnabled;
        config.isBackgroundSession = _isBackgroundSession;
        config.AppGroup = [_AppGroup copyWithZone:zone];
    }
    return config;
}
@end
