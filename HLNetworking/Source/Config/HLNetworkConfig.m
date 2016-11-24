//
//  HLNetworkConfig.m
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLNetworkConfig.h"
#import "HLAPIType.h"

NSString * HLDefaultGeneralErrorString            = @"服务器连接错误，请稍候重试";
NSString * HLDefaultFrequentRequestErrorString    = @"请求发送速度太快, 请稍候重试";
NSString * HLDefaultNetworkNotReachableString     = @"网络不可用，请稍后重试";

@implementation HLNetworkConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.generalErrorTypeStr = HLDefaultGeneralErrorString;
        self.frequentRequestErrorStr = HLDefaultFrequentRequestErrorString;
        self.networkNotReachableErrorStr = HLDefaultNetworkNotReachableString;
        self.isNetworkingActivityIndicatorEnabled = YES;
        self.isErrorCodeDisplayEnabled = YES;
        self.maxHttpConnectionPerHost = MAX_HTTP_CONNECTION_PER_HOST;
        self.apiVersion = [self getCurrentVersion];
        self.isJudgeVersion = [[NSUserDefaults standardUserDefaults] boolForKey:@"isR"] ? : YES;
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
    HLNetworkConfig *config = [[HLNetworkConfig allocWithZone:zone] init];
    config.generalErrorTypeStr = self.generalErrorTypeStr;
    config.frequentRequestErrorStr = self.frequentRequestErrorStr;
    config.networkNotReachableErrorStr = self.networkNotReachableErrorStr;
    config.isErrorCodeDisplayEnabled = self.isErrorCodeDisplayEnabled;
    config.baseURL = self.baseURL;
    config.apiVersion = self.apiVersion;
    config.userAgent = self.userAgent;
    config.maxHttpConnectionPerHost = self.maxHttpConnectionPerHost;
    return config;
}

+ (HLNetworkConfig *)config {
    return [[HLNetworkConfig alloc] init];
}
@end
