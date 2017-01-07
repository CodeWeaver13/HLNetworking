//
//  HLNetworkLoggerConfig.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLNetworkLoggerConfig.h"
@interface HLNetworkLoggerConfig ()
// 系统版本
@property (nonatomic, copy, readwrite) NSString *osVersion;

// 设备型号
@property (nonatomic, copy, readwrite) NSString *deviceModel;

// 设备标识
@property (nonatomic, copy, readwrite) NSString *UDID;
@end

@implementation HLNetworkLoggerConfig
+ (instancetype)config {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _channelID = @"";
        _appKey = @"";
        _appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] ?: @"";
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"";
        _serviceType = @"";
        _enableLocalLog = NO;
        _loggerLevel = HLNetworkLoggerNoneLevel;
        _logAutoSaveCount = 50;
        _loggerType = HLNetworkLoggerTypeJSON;
    }
    return self;
}

- (NSString *)logFilePath {
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"com.qkhl.HLNetworking/log"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDateFormatter *myFormatter = [[NSDateFormatter alloc] init];
    [myFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString *dateString = [myFormatter stringFromDate:[NSDate date]];
    return [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log", dateString]];
}
@end
