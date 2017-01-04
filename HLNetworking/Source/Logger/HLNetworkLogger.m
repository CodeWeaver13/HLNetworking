//
//  HLNetworkLogger.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLNetworkLogger.h"
#import "HLNetworkMacro.h"

// 创建任务队列
static dispatch_queue_t qkhl_log_queue() {
    static dispatch_queue_t qkhl_log_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        qkhl_log_queue =
        dispatch_queue_create("com.qkhl.networking.wangshiyu13.log.queue", DISPATCH_QUEUE_SERIAL);
    });
    return qkhl_log_queue;
}

@interface HLNetworkLogger ()

@property (nonatomic, strong, readwrite) HLNetworkLoggerConfig *config;

@property (nonatomic, strong) NSMutableArray <NSDictionary *>*debugInfoArray;

@end

@implementation HLNetworkLogger

#pragma mark - logger
+ (void)logInfoWithDebugMessage:(HLDebugMessage *)debugMessage {
    [[self sharedInstance] logInfoWithDebugMessage:debugMessage];
}

+ (void)writeToFile {
    [[self sharedInstance] writeToFile];
}

+ (void)addLogInfoWithDebugMessage:(HLDebugMessage *)debugMessage {
    [[self sharedInstance] addLogInfoWithDebugMessage:debugMessage];
}

- (void)logInfoWithDebugMessage:(HLDebugMessage *)debugMessage {
#if DEBUG
    NSLog(@"%@", debugMessage);
#endif
}

- (void)writeToFile {
    dispatch_async(qkhl_log_queue(), ^{
        if (self.config.enableLocalLog) {
            NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:self.config.logFilePath append:YES];
            [outputStream open];
            BOOL succeed = [NSJSONSerialization writeJSONObject:self.debugInfoArray toStream:outputStream options:NSJSONWritingPrettyPrinted error:nil];
            [outputStream close];
            if (succeed) {
                [self.debugInfoArray removeAllObjects];
            }
        }
    });
}

- (void)addLogInfoWithDebugMessage:(HLDebugMessage *)debugMessage {
    dispatch_async(qkhl_log_queue(), ^{
        if (self.config.enableLocalLog) {
            if (self.debugInfoArray.count > self.config.logAutoSaveCount) {
                [self writeToFile];
            }
            [self.debugInfoArray addObject:[debugMessage toDictionary]];
        }
    });
}

#pragma mark - setupConfig
- (void)setupConfig:(void (^)(HLNetworkLoggerConfig * _Nonnull))configBlock {
    HL_SAFE_BLOCK(configBlock, self.config);
}

+ (void)setupConfig:(void (^)(HLNetworkLoggerConfig * _Nonnull))configBlock {
    [[self sharedInstance] setupConfig:configBlock];
}

#pragma mark - init
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HLNetworkLogger *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [HLNetworkLoggerConfig config];
        _debugInfoArray = [NSMutableArray array];
    }
    return self;
}

- (NSMutableArray<NSDictionary *> *)debugInfoArray {
    if (_debugInfoArray.count == 0) {
        [_debugInfoArray addObject:@{@"AppInfo": @{@"channelID": _config.channelID,
                                                   @"appKey": _config.appKey,
                                                   @"appName": _config.appName,
                                                   @"appVersion": _config.appVersion,
                                                   @"serviceType": _config.serviceType}}];
    }
    return _debugInfoArray;
}
@end
