//
//  HLNetworkLoggerConfig.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, HLNetworkLoggerLevel) {
    HLNetworkLoggerNoneLevel = 0,
    HLNetworkLoggerNetErrorLevel = 1 << 0,
    HLNetworkLoggerRequestLevel = 1 << 1,
    HLNetworkLoggerResponseLevel = 1 << 2,
    HLNetworkLoggerAllLevel = 1 << 3
};

@interface HLNetworkLoggerConfig : NSObject

// 渠道ID
@property (nonatomic, strong) NSString *channelID;

// app标志
@property (nonatomic, strong) NSString *appKey;

// app名字
@property (nonatomic, strong) NSString *appName;

// app名字
@property (nonatomic, strong) NSString *appVersion;

// 服务名
@property (nonatomic, assign) NSString *serviceType;

// 是否开启本地日志
@property (nonatomic, assign) BOOL enableLocalLog;

// 日志文件路径
@property (nonatomic, strong) NSString *logFilePath;

// 日志自动保存数，默认为50次保存一次
@property (nonatomic, assign) NSUInteger logAutoSaveCount;

// 日志等级
@property (nonatomic, assign) HLNetworkLoggerLevel loggerLevel;

+ (instancetype)config;
@end
