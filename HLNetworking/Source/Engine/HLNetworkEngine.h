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
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
// 单例
+ (instancetype)sharedEngine;

// 发送请求
// requestObject为HLAPI或者HLTask对象
- (void)sendRequest:(__kindof HLURLRequest *)requestObject
          andConfig:(HLNetworkConfig *)config
       progressBack:(HLProgressBlock)progressCallBack
           callBack:(HLCallbackBlock)callBack;

// 取消请求
- (void)cancelRequestByIdentifier:(NSString *)identifier;

// 如果task不存在则返回NSNull对象
- (NSURLSessionTask *)requestByIdentifier:(NSString *)identifier;

#pragma mark - reachability相关
// 开始监听，domain为需要监听的域名
- (void)listeningWithDomain:(NSString *)domain listeningBlock:(HLReachabilityBlock)listener;
// 停止监听，domain为需要停止的域名
- (void)stopListeningWithDomain:(NSString *)domain;
@end
