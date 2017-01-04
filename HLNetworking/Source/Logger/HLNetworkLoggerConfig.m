//
//  HLNetworkLoggerConfig.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLNetworkLoggerConfig.h"

@implementation HLNetworkLoggerConfig
+ (instancetype)config {
    return [[self alloc] init];
}

- (instancetype)init
{
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
    }
    return self;
}

- (NSString *)logFilePath {
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"com.qkhl.HLNetworking/log"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDateFormatter *myFormatter = [[NSDateFormatter alloc] init];
    [myFormatter setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
    NSString *dateString = [myFormatter stringFromDate:[NSDate date]];
    _logFilePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log", dateString]];
    return _logFilePath;
}
@end
