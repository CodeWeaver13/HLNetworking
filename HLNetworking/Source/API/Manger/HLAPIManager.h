//
//  HLAPIManager.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/17.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

// 设置是否为审核版本
extern void HLJudgeVersionSwitch(BOOL isR);

@protocol HLNetworkErrorProtocol;
@protocol HLAPIResponseDelegate;
@class HLNetworkConfig;
@class HLAPI;
@class HLAPIBatchRequests;
@class HLAPISyncBatchRequests;
NS_ASSUME_NONNULL_BEGIN
@interface HLAPIManager : NSObject

@property (nonatomic, strong, nonnull) HLNetworkConfig *config;

//@property (nonatomic, weak, nullable) id<HLAPIResponseDelegate> responseDelegate;

// 单例
+ (HLAPIManager *)shared;

/**
 *  发送API请求
 *
 *  @param api 要发送的api
 */
- (void)sendAPIRequest:(HLAPI *)api;

/**
 *  取消API请求
 *
 *  @description
 *      如果该请求已经发送或者正在发送，则无法取消
 *
 *  @param api 要取消的api
 */
- (void)cancelAPIRequest:(HLAPI *)api;

/**
 *  发送一系列API请求
 *
 *  @param apis 待发送的API请求集合
 */
- (void)sendBatchAPIRequests:(HLAPIBatchRequests *)apis;


/**
 发送同步请求

 @param apis 带发送的同步请求集合
 */
- (void)sendSyncBatchAPIRequests:(HLAPISyncBatchRequests *)apis;


/**
 移除网络请求监听者

 @param observer 监听者
 */
- (void)registerNetworkResponseObserver:(id<HLAPIResponseDelegate>)observer;

/**
 删除网络请求监听者
 
 @param observer 监听者
 */
- (void)removeNetworkResponseObserver:(id<HLAPIResponseDelegate>)observer;

/**
 *  添加网络传输错误时的监控observer
 *
 *  @param observer 遵循HLNetworkErrorProtocol的observer
 */
- (void)registerNetworkErrorObserver:(id<HLNetworkErrorProtocol>)observer;

/**
 *  删除网络传输错误时的监控observer
 *
 *  @param observer 遵循HLNetworkErrorProtocol的observer
 */
- (void)removeNetworkErrorObserver:(id<HLNetworkErrorProtocol>)observer;

@end
NS_ASSUME_NONNULL_END
