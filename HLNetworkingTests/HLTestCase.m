//
//  HLTestCase.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/2/9.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLTestCase.h"

@implementation HLTestCase
- (void)setUp {
    [super setUp];
    self.networkTimeout = 20.0;
//    [HLNetworkLogger setupConfig:^(HLNetworkLoggerConfig * _Nonnull config) {
//        config.enableLocalLog = YES;
//        config.logAutoSaveCount = 5;
//        config.loggerType = HLNetworkLoggerTypePlist;
//    }];
//    [HLNetworkLogger setDelegate:self];
//    [HLNetworkLogger startLogging];
    
    // setupNetwork
    [HLNetworkManager setupConfig:^(HLNetworkConfig * _Nonnull config) {
        config.request.baseURL = @"https://httpbin.org/";
        config.policy.isBackgroundSession = NO;
        config.request.apiVersion = nil;
        config.request.defaultParams = @{@"global_param": @"global param value"};
        config.request.defaultHeaders = @{@"global_header": @"global header value"};
    }];
}

- (void)tearDown {
    [super tearDown];
}

- (void)waitForExpectationsWithCommonTimeout {
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler {
    [self waitForExpectationsWithTimeout:self.networkTimeout handler:handler];
}

- (NSDictionary *)customInfoWithMessage:(HLDebugMessage *)message {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"Time"] = message.timeString;
    dict[@"RequestObject"] = [message.requestObject toDictionary];
    dict[@"Response"] = [message.response toDictionary];
    return [dict copy];
}

- (NSDictionary *)customHeaderWithMessage:(HLNetworkLoggerConfig *)config {
    return @{@"AppInfo": @{@"OSVersion": [UIDevice currentDevice].systemVersion,
                           @"DeviceType": [UIDevice currentDevice].hl_machineType,
                           @"UDID": [UIDevice currentDevice].hl_udid,
                           @"UUID": [UIDevice currentDevice].hl_uuid,
                           @"MacAddressMD5": [UIDevice currentDevice].hl_macaddressMD5,
                           @"ChannelID": config.channelID,
                           @"AppKey": config.appKey,
                           @"AppName": config.appName,
                           @"AppVersion": config.appVersion,
                           @"ServiceType": config.serviceType}};
}
@end
