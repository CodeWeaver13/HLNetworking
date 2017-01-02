//
//  HLNetworkPolicyConfig.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLNetworkPolicyConfig : NSObject<NSCopying>
// 是否为后台模式所用的GroupID，该选项只对Task有影响
@property (nonatomic, copy) NSString *AppGroup;

// 是否为后台模式，该选项只对Task有影响
@property (nonatomic, assign) BOOL isBackgroundSession;

// 出现网络请求错误时，是否在请求错误的文字后加上{code}，默认为YES
@property (nonatomic, assign) BOOL isErrorCodeDisplayEnabled;

// 请求缓存策略，默认为NSURLRequestUseProtocolCachePolicy
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;

// URLCache设置
@property (nonatomic, assign) NSURLCache *URLCache;

// 快速构建config
+ (HLNetworkPolicyConfig *)config;

// 请使用config
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
