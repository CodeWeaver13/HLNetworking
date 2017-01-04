//
//  HLNetworkLogger.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLNetworkLogger.h"
#import "HLNetworkMacro.h"

@interface HLNetworkLogger ()

@property (nonatomic, strong, readwrite) HLNetworkLoggerConfig *config;

@end

@implementation HLNetworkLogger

#pragma mark - logger
+ (void)writeToFile {
    
}

+ (void)logInfoWithDebugMessage:(HLDebugMessage *)debugMessage {
    
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
        _config = [[HLNetworkLoggerConfig alloc] init];
    }
    return self;
}
@end
