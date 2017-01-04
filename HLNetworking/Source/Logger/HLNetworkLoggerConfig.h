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

// 是否使用本地日志
@property (nonatomic, assign) BOOL enableWriteToFile;

// 日志文件路径
@property (nonatomic, strong) NSString *logFilePath;

// 日志等级
@property (nonatomic, assign) HLNetworkLoggerLevel loggerLevel;

@end
