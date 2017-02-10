//
//  HLNetworkRequestConfig.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
// 默认的请求超时时间
#define HL_API_REQUEST_TIME_OUT     15

// 每个host最大连接数
#define MAX_HTTP_CONNECTION_PER_HOST 5

@interface HLNetworkRequestConfig : NSObject<NSCopying>
// API请求的自定义队列
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

// 默认的parameters，可以在HLAPI中选择是否使用，默认开启
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSObject *> *defaultParams;

// 默认的header，可以在HLAPI中覆盖
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *defaultHeaders;

// 全局的baseURL，HLAPI的baseURL会覆盖该参数
@property (nonatomic, copy, nullable) NSString *baseURL;
// api版本，用于拼接在请求的Path上
// 默认为infoPlist中的CFBundleShortVersionString，格式为v{version}{r}，审核版本为r
@property (nonatomic, copy, nullable) NSString *apiVersion;

// 是否为审核版本，作用于apiVersion，存储在NSUserDefaults中，key为isR
@property (nonatomic, assign) BOOL isJudgeVersion;

// UserAgent，request header中的UA，默认为nil
@property (nonatomic, copy, nullable) NSString *userAgent;

// 每个Host的最大连接数，默认为5
@property (nonatomic, assign) NSUInteger maxHttpConnectionPerHost;

// 网络状态不好时自动重试次数，默认为0
@property (nonatomic, assign) NSUInteger retryCount;

// 请求超时时间，默认为15秒
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

// 获取当前版本
- (nonnull NSString *)getCurrentVersion;

// 快速构建config
+ (nonnull HLNetworkRequestConfig *)config;

// 请使用config
- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;
@end
