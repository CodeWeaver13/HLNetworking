//
//  HLNetworkConfig.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLSecurityPolicyConfig.h"
NS_ASSUME_NONNULL_BEGIN
// 默认的请求超时时间
#define HL_API_REQUEST_TIME_OUT     15

// 每个host最大连接数
#define MAX_HTTP_CONNECTION_PER_HOST 5

FOUNDATION_EXPORT NSString * const HLDefaultGeneralErrorString;
FOUNDATION_EXPORT NSString * const HLDefaultFrequentRequestErrorString;
FOUNDATION_EXPORT NSString * const HLDefaultNetworkNotReachableString;

@interface HLNetworkConfig : NSObject<NSCopying>

// 请求的自定义队列
@property (nonatomic, strong) dispatch_queue_t apiCallbackQueue;

// 默认的parameters，可以在HLAPI中选择是否使用，默认开启
@property (nonatomic, strong) NSDictionary<NSString *, NSObject *> *defaultParams;

// 默认的header，可以在HLAPI中覆盖
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *defaultHeaders;

// 全局的baseURL，HLAPI的baseURL会覆盖该参数
@property (nonatomic, copy, nullable) NSString *baseURL;

// 是否为后台模式所用的GroupID，该选项只对Task有影响
@property (nonatomic, copy) NSString *AppGroup;

// 是否为后台模式，该选项只对Task有影响
@property (nonatomic, assign) BOOL isBackgroundSession;

// 出现网络请求时，为了给用户比较好的用户体验，而使用的错误提示文字,
// 默认为：服务器连接错误，请稍候重试
@property (nonatomic, copy) NSString *generalErrorTypeStr;

// 用户频繁发送同一个请求，使用的错误提示文字
// 默认为：请求发送速度太快, 请稍候重试
@property (nonatomic, copy) NSString *frequentRequestErrorStr;

// 网络请求开始时，会先检测相应网络域名的Reachability，如果不可达，则直接返回该错误文字
// 默认为：网络不可用，请稍后重试
@property (nonatomic, copy) NSString *networkNotReachableErrorStr;

// 出现网络请求错误时，是否在请求错误的文字后加上{code}，默认为YES
@property (nonatomic, assign) BOOL isErrorCodeDisplayEnabled;

// api版本，用于拼接在请求的Path上
// 默认为infoPlist中的CFBundleShortVersionString，格式为v{version}{r}，审核版本为r
@property (nonatomic, copy, nullable) NSString *apiVersion;

// 是否为审核版本，作用于apiVersion，存储在NSUserDefaults中，key为isR
@property (nonatomic, assign) BOOL isJudgeVersion;

// UserAgent，request header中的UA，默认为nil
@property (nonatomic, copy, nullable) NSString *userAgent;

// 每个Host的最大连接数，默认为5
@property (nonatomic, assign) NSUInteger maxHttpConnectionPerHost;

// 请求超时时间，默认为15秒
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

// 请求缓存策略，默认为NSURLRequestUseProtocolCachePolicy
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;

// URLCache设置
@property (nonatomic, assign) NSURLCache *URLCache;

// 网络指示器（状态栏），默认为YES
@property (nonatomic, assign) BOOL isNetworkingActivityIndicatorEnabled;

// 是否启用reachability，baseURL为domain
@property (nonatomic, assign) BOOL enableReachability;

// 默认的安全策略配置
@property (nonatomic, strong) HLSecurityPolicyConfig *defaultSecurityPolicy;

// 快速构建config
+ (HLNetworkConfig *)config;

// 请使用config
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
