//
//  HLNetworkConfig.m
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLNetworkConfig.h"
#import "HLAPIType.h"

NSString * const HLDefaultGeneralErrorString            = @"服务器连接错误，请稍候重试";
NSString * const HLDefaultFrequentRequestErrorString    = @"请求发送速度太快, 请稍候重试";
NSString * const HLDefaultNetworkNotReachableString     = @"网络不可用，请稍后重试";

@implementation HLNetworkConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _generalErrorTypeStr = HLDefaultGeneralErrorString;
        _frequentRequestErrorStr = HLDefaultFrequentRequestErrorString;
        _networkNotReachableErrorStr = HLDefaultNetworkNotReachableString;
        _isNetworkingActivityIndicatorEnabled = YES;
        _isErrorCodeDisplayEnabled = YES;
        _maxHttpConnectionPerHost = MAX_HTTP_CONNECTION_PER_HOST;
        _requestTimeoutInterval = HL_API_REQUEST_TIME_OUT;
        _cachePolicy = NSURLRequestUseProtocolCachePolicy;
        _URLCache = [NSURLCache sharedURLCache];
        _apiVersion = [self getCurrentVersion];
        _isJudgeVersion = [[NSUserDefaults standardUserDefaults] boolForKey:@"isR"] ? : YES;
        _enableReachability = FALSE;
    }
    return self;
}

+ (HLNetworkConfig *)config {
    return [[self alloc] init];
}

- (NSString *)getCurrentVersion {
    NSString *origin = [[NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"] stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (self.isJudgeVersion) {
        return [NSString stringWithFormat:@"v%@r", origin];
    } else {
        return [NSString stringWithFormat:@"v%@", origin];
    }
}

- (id)copyWithZone:(NSZone *)zone {
    HLNetworkConfig *config = [[[self class] alloc] init];
    if (config) {
        config.generalErrorTypeStr = [_generalErrorTypeStr copyWithZone:zone];
        config.frequentRequestErrorStr = [_frequentRequestErrorStr copyWithZone:zone];
        config.networkNotReachableErrorStr = [_networkNotReachableErrorStr copyWithZone:zone];
        config.isErrorCodeDisplayEnabled = _isErrorCodeDisplayEnabled;
        config.baseURL = [_baseURL copyWithZone:zone];
        config.apiVersion = [_apiVersion copyWithZone:zone];
        config.userAgent = [_userAgent copyWithZone:zone];
        config.maxHttpConnectionPerHost = _maxHttpConnectionPerHost;
    }
    return config;
}
@end
