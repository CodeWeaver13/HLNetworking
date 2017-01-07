//
//  HLNetworkLoggerConfig.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class HLDebugMessage;

typedef NS_OPTIONS(NSUInteger, HLNetworkLoggerLevel) {
    HLNetworkLoggerNoneLevel = 0,
    HLNetworkLoggerNetErrorLevel = 1 << 0,
    HLNetworkLoggerRequestLevel = 1 << 1,
    HLNetworkLoggerResponseLevel = 1 << 2,
    HLNetworkLoggerAllLevel = 1 << 3
};

typedef NS_ENUM(NSUInteger, HLNetworkLoggerType) {
    HLNetworkLoggerTypeJSON,
    HLNetworkLoggerTypePlist
};

@interface HLNetworkLoggerConfig : NSObject

// 渠道ID
@property (nonatomic, copy) NSString *channelID;

// app标志
@property (nonatomic, copy) NSString *appKey;

// app名字
@property (nonatomic, copy) NSString *appName;

// app名字
@property (nonatomic, copy) NSString *appVersion;

// 服务名
@property (nonatomic, copy) NSString *serviceType;

// 是否开启本地日志
@property (nonatomic, assign) BOOL enableLocalLog;

// 日志自动保存数，默认为50次保存一次
@property (nonatomic, assign) NSUInteger logAutoSaveCount;

// 日志等级
@property (nonatomic, assign) HLNetworkLoggerLevel loggerLevel;

// 日志保存类型
@property (nonatomic, assign) HLNetworkLoggerType loggerType;

// 日志文件路径
@property (nonatomic, copy, readonly) NSString *logFilePath;

+ (instancetype)config;
@end
