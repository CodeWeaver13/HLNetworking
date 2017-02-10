//
//  HLNetworkConfig.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLSecurityPolicyConfig.h"
#import "HLNetworkTipsConfig.h"
#import "HLNetworkRequestConfig.h"
#import "HLNetworkPolicyConfig.h"
NS_ASSUME_NONNULL_BEGIN

DISPATCH_EXPORT void dispatch_async_main(dispatch_queue_t queue, dispatch_block_t block);

@interface HLNetworkConfig : NSObject<NSCopying>

// 提示相关参数
@property (nonatomic, strong) HLNetworkTipsConfig *tips;

// 请求相关参数
@property (nonatomic, strong) HLNetworkRequestConfig *request;

// 网络策略相关参数
@property (nonatomic, strong) HLNetworkPolicyConfig *policy;

// 安全策略相关参数
@property (nonatomic, strong) HLSecurityPolicyConfig *defaultSecurityPolicy;

// 是否启用reachability，baseURL为domain
@property (nonatomic, assign) BOOL enableReachability;

// 是否开启网络debug日志，该选项会在控制台输出所有网络回调日志，并且在Release模式下无效
@property (nonatomic, assign) BOOL enableGlobalLog;

// 快速构建config
+ (HLNetworkConfig *)config;

// 请使用config
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
