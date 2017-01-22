//
//  HLAPIEngine.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/22.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLAPIType.h"
@class HLAPI;
@class HLNetworkConfig;

typedef void(^HLAPICallbackBlock)(HLAPI * api, id responseObject, NSError *error);

@interface HLAPIEngine : NSObject
// 请使用sharedEngine
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
// 单例
+ (instancetype)sharedEngine;

// 发送请求
- (void)sendRequest:(HLAPI *)api
          andConfig:(HLNetworkConfig *)config
       progressBack:(HLProgressBlock)progressCallBack
           callBack:(HLAPICallbackBlock)callBack;

// 取消请求
- (void)cancelRequest:(HLAPI *)api;

// 如果task不存在则返回NSNull对象
- (NSURLSessionDataTask *)requestForAPI:(HLAPI *)api;

#pragma mark - reachability相关
// 开始监听，domain为需要监听的域名
- (void)listeningWithDomain:(NSString *)domain listeningBlock:(HLReachabilityBlock)listener;
// 停止监听，domain为需要停止的域名
- (void)stopListeningWithDomain:(NSString *)domain;

@end
