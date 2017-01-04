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
NS_ASSUME_NONNULL_BEGIN
@interface HLNetworkLogger : NSObject

@property (nonatomic, strong, readonly) HLNetworkLoggerConfig *config;

+ (void)writeToFile;

+ (void)logInfoWithDebugMessage:(HLDebugMessage *)debugMessage;

+ (void)setupConfig:(void(^)(HLNetworkLoggerConfig *config))configBlock;

+ (instancetype)sharedInstance;

@end
NS_ASSUME_NONNULL_END
