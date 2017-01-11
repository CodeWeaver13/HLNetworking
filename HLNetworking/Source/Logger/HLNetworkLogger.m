//
//  HLNetworkLogger.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLNetworkLogger.h"
#import "HLNetworkMacro.h"
#import "UIDevice+deviceInfo.h"

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

@property (nonatomic, weak, nullable) id<HLNetworkCustomLoggerDelegate> delegate;

@property (nonatomic, assign) BOOL enable;

@property (nonatomic, strong) NSMutableArray <NSDictionary *>*debugInfoArray;

@end

@implementation HLNetworkLogger

#pragma mark - logger
- (id<HLNetworkCustomLoggerDelegate>)currentDelegate {
    return [self delegate];
}

- (void)logInfoWithDebugMessage:(HLDebugMessage *)debugMessage {
#if DEBUG
    NSLog(@"%@", debugMessage);
#endif
}

- (NSArray <NSString *>*)logFilePaths {
    NSString *dirPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"com.qkhl.HLNetworking/log"];
    NSArray <NSString *>*fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
    NSMutableArray <NSString *>*tmpArray = [NSMutableArray array];
    for (NSString *fileName in fileList) {
        NSString *path = [NSString stringWithFormat:@"%@/%@", dirPath, fileName];
        [tmpArray addObject:path];
    }
    return [tmpArray copy];
}

- (void)writeToFile {
    dispatch_async(qkhl_log_queue(), ^{
        if (self.config.enableLocalLog) {
            BOOL succeed = NO;
            if (self.config.loggerType == HLNetworkLoggerTypeJSON) {
                NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:self.config.logFilePath append:YES];
                [outputStream open];
                succeed = [NSJSONSerialization writeJSONObject:self.debugInfoArray toStream:outputStream options:NSJSONWritingPrettyPrinted error:nil];
                [outputStream close];
            } else {
                succeed = [self.debugInfoArray writeToFile:self.config.logFilePath atomically:YES];
            }
            if (succeed) {
                [self.debugInfoArray removeAllObjects];
            }
        }
    });
}

- (void)addLogInfoWithDictionary:(NSDictionary *)dictionary {
    dispatch_async(qkhl_log_queue(), ^{
        if (self.config.enableLocalLog) {
            if (self.debugInfoArray.count > self.config.logAutoSaveCount) {
                [self writeToFile];
            }
            [self.debugInfoArray addObject:dictionary];
        }
    });
}

- (void)startLogging {
    self.enable = YES;
}

- (void)stopLogging {
    self.enable = NO;
}

#pragma mark - setupConfig
- (void)setupConfig:(void (^)(HLNetworkLoggerConfig * _Nonnull))configBlock {
    HL_SAFE_BLOCK(configBlock, self.config);
}

#pragma mark - init
+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static HLNetworkLogger *shared;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [HLNetworkLoggerConfig config];
        _enable = NO;
        _debugInfoArray = [NSMutableArray array];
    }
    return self;
}

- (NSMutableArray<NSDictionary *> *)debugInfoArray {
    if (_debugInfoArray.count == 0) {
        NSDictionary *infoHeader;
        if ([self.delegate respondsToSelector:@selector(customHeaderWithMessage:)]) {
            infoHeader = [self.delegate customHeaderWithMessage:self.config];
        } else {
            infoHeader = @{@"AppInfo": @{@"OSVersion": [UIDevice currentDevice].systemVersion,
                                         @"DeviceType": [UIDevice currentDevice].hl_machineType,
                                         @"UDID": [UIDevice currentDevice].hl_udid,
                                         @"UUID": [UIDevice currentDevice].hl_uuid,
                                         @"MacAddressMD5": [UIDevice currentDevice].hl_macaddressMD5,
                                         @"ChannelID": _config.channelID,
                                         @"AppKey": _config.appKey,
                                         @"AppName": _config.appName,
                                         @"AppVersion": _config.appVersion,
                                         @"ServiceType": _config.serviceType}};
        }
        [_debugInfoArray addObject:infoHeader];
    }
    return _debugInfoArray;
}

#pragma mark - static method
+ (id<HLNetworkCustomLoggerDelegate>)currentDelegate {
    return [[self shared] currentDelegate];
}

+ (void)setDelegate:(id<HLNetworkCustomLoggerDelegate>)delegate {
    [[self shared] setDelegate:delegate];
}

+ (NSArray <NSString *>*)logFilePaths {
    return [[self shared] logFilePaths];
}

+ (void)setupConfig:(void (^)(HLNetworkLoggerConfig * _Nonnull))configBlock {
    [[self shared] setupConfig:configBlock];
}

+ (BOOL)isEnable {
    return [[self shared] enable];
}

+ (void)logInfoWithDebugMessage:(HLDebugMessage *)debugMessage {
    [[self shared] logInfoWithDebugMessage:debugMessage];
}

+ (void)writeToFile {
    [[self shared] writeToFile];
}

+ (void)addLogInfoWithDictionary:(NSDictionary *)dictionary {
    [[self shared] addLogInfoWithDictionary:dictionary];
}

+ (void)startLogging {
    [[self shared] startLogging];
}

+ (void)stopLogging {
    [[self shared] stopLogging];
}
@end
