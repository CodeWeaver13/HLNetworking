//
//  HLNetworkRequestConfig.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLNetworkRequestConfig.h"

@implementation HLNetworkRequestConfig

+ (HLNetworkRequestConfig *)config {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _callbackQueue = nil;
        _maxHttpConnectionPerHost = MAX_HTTP_CONNECTION_PER_HOST;
        _requestTimeoutInterval = HL_API_REQUEST_TIME_OUT;
        _retryCount = 0;
        _apiVersion = nil;
        _isJudgeVersion = [[NSUserDefaults standardUserDefaults] boolForKey:@"isR"] ? : YES;
    }
    return self;
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
    HLNetworkRequestConfig *config = [[[self class] alloc] init];
    if (config) {
        config.defaultHeaders = [_defaultHeaders copyWithZone:zone];
        config.defaultParams = [_defaultParams copyWithZone:zone];
        config.baseURL = [_baseURL copyWithZone:zone];
        config.apiVersion = [_apiVersion copyWithZone:zone];
        config.userAgent = [_userAgent copyWithZone:zone];
        config.isJudgeVersion = _isJudgeVersion;
        config.requestTimeoutInterval = _requestTimeoutInterval;
        config.maxHttpConnectionPerHost = _maxHttpConnectionPerHost;
    }
    return config;
}
@end
