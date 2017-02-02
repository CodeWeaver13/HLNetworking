//
//  HLNetworkEngine.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/22.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLNetworkConst.h"
@class HLNetworkConfig;
@class HLURLRequest;

@interface HLNetworkEngine : NSObject
// 请使用sharedEngine
- (_Nonnull instancetype)init NS_UNAVAILABLE;
+ (_Nonnull instancetype)new NS_UNAVAILABLE;
// 单例
+ (_Nonnull instancetype)sharedEngine;

// 发送请求
// requestObject为HLAPI或者HLTask对象
- (void)sendRequest:(__kindof HLURLRequest * _Nonnull)requestObject
          andConfig:(HLNetworkConfig * _Nonnull)config
       progressBack:(HLProgressBlock _Nullable)progressCallBack
           callBack:(HLCallbackBlock _Nullable)callBack;

// 取消请求
- (void)cancelRequestByIdentifier:(NSString * _Nonnull)identifier;

// 如果task不存在则返回NSNull对象
- (__kindof NSURLSessionTask * _Nullable)requestByIdentifier:(NSString * _Nonnull)identifier;

#pragma mark - reachability相关
// 开始监听，domain为需要监听的域名
- (void)listeningWithDomain:(NSString * _Nonnull)domain listeningBlock:(HLReachabilityBlock _Nonnull)listener;
// 停止监听，domain为需要停止的域名
- (void)stopListeningWithDomain:(NSString * _Nonnull)domain;
@end
