//
//  HLNetworkTipsConfig.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLNetworkTipsConfig.h"

NSString * const HLDefaultGeneralErrorString            = @"服务器连接错误，请稍候重试";
NSString * const HLDefaultFrequentRequestErrorString    = @"请求发送速度太快, 请稍候重试";
NSString * const HLDefaultNetworkNotReachableString     = @"网络不可用，请稍后重试";

@implementation HLNetworkTipsConfig

+ (HLNetworkTipsConfig *)config {
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _generalErrorTypeStr = HLDefaultGeneralErrorString;
        _frequentRequestErrorStr = HLDefaultFrequentRequestErrorString;
        _networkNotReachableErrorStr = HLDefaultNetworkNotReachableString;
        _isNetworkingActivityIndicatorEnabled = YES;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    HLNetworkTipsConfig *config = [[[self class] alloc] init];
    if (config) {
        config.generalErrorTypeStr = [_generalErrorTypeStr copyWithZone:zone];
        config.frequentRequestErrorStr = [_frequentRequestErrorStr copyWithZone:zone];
        config.networkNotReachableErrorStr = [_networkNotReachableErrorStr copyWithZone:zone];
        config.isNetworkingActivityIndicatorEnabled = _isNetworkingActivityIndicatorEnabled;
    }
    return config;
}
@end
