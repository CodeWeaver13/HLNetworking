//
//  HLNetworkLogger.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLNetworkLoggerConfig.h"
#import "HLDebugMessage.h"
#import "UIDevice+deviceInfo.h"
NS_ASSUME_NONNULL_BEGIN
@protocol HLNetworkCustomLoggerDelegate <NSObject>
@required
// 根据传入的message拼接存储的日志结构
- (NSDictionary *)customInfoWithMessage:(HLDebugMessage *)message;
@optional
// 根据传入的设置拼接日志头部信息
- (NSDictionary *)customHeaderWithMessage:(HLNetworkLoggerConfig *)config;
@end

@interface HLNetworkLogger : NSObject

@property (nonatomic, strong, readonly) HLNetworkLoggerConfig *config;
// 设置代理
+ (void)setDelegate:(id<HLNetworkCustomLoggerDelegate>)delegate;

// 写入后会清空当前记录的日志
+ (void)writeToFile;

// 打印debugMessage，该方法只在debug模式下有效
+ (void)logInfoWithDebugMessage:(HLDebugMessage *)debugMessage;

// 添加日志
+ (void)addLogInfoWithDictionary:(NSDictionary *)dictionary;

// 日志文件路径数组
+ (nullable NSArray <NSString *>*)logFilePaths;

// 设置config
+ (void)setupConfig:(void(^)(HLNetworkLoggerConfig *config))configBlock;

// 是否已经开启日志
+ (BOOL)isEnable;

// 开启日志
+ (void)startLogging;

// 关闭日志
+ (void)stopLogging;

// 当前代理对象
+ (nullable id<HLNetworkCustomLoggerDelegate>)currentDelegate;

// 单例对象
+ (instancetype)shared;

@end
NS_ASSUME_NONNULL_END
