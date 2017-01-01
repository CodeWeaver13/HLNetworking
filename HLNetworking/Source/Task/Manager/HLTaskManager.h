//
//  HLTaskManager.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/25.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HLNetworkConfig;
@class HLTask;

NS_ASSUME_NONNULL_BEGIN
@protocol HLTaskResponseProtocol;

@interface HLTaskManager : NSObject

@property (nonatomic, strong, readonly) HLNetworkConfig *config;
// 请使用manager
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)manager;
// 配置设置
- (void)setupConfig:(void(^)(HLNetworkConfig *config))configBlock;

// 发送Task请求
- (void)send:(HLTask *)task;

// 取消Task，如果该请求已经发送或者正在发送，则不保证一定可以取消
- (void)cancel:(HLTask *)task;

// 恢复Task
- (void)resume:(HLTask *)task;

// 暂停Task
- (void)pause:(HLTask *)task;

// 注册网络请求监听者
- (void)registerResponseObserver:(id<HLTaskResponseProtocol>)observer;

// 删除网络请求监听者
- (void)removeResponseObserver:(id<HLTaskResponseProtocol>)observer;

#pragma mark - 单例下用的静态方法
// 统一管理单例
+ (nonnull HLTaskManager *)sharedManager;

// 为sharedManager单例配置设置
+ (void)setupConfig:(void(^)(HLNetworkConfig *config))configBlock;

// 发送Task请求
+ (void)send:(HLTask *)task;

// 取消Task，如果该请求已经发送或者正在发送，则不保证一定可以取消
+ (void)cancel:(HLTask *)task;

// 恢复Task
+ (void)resume:(HLTask *)task;

// 暂停Task
+ (void)pause:(HLTask *)task;

// 注册网络请求监听者
+ (void)registerResponseObserver:(id<HLTaskResponseProtocol>)observer;

// 删除网络请求监听者
+ (void)removeResponseObserver:(id<HLTaskResponseProtocol>)observer;
@end
NS_ASSUME_NONNULL_END
