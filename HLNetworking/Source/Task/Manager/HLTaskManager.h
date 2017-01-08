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
@class HLTaskGroup;

NS_ASSUME_NONNULL_BEGIN
@protocol HLTaskResponseProtocol <NSObject>
/**
 快速返回需要监听的task对象
 
 @param ... tasks
 @return HLTask对象数组
 */
#define HLObserverTasks(...) \
- (NSArray <HLTask *>* _Nonnull)requestTasks { \
return [NSArray arrayWithObjects:__VA_ARGS__, nil]; \
}

@required
/**
 用于返回需要监听的task对象
 
 @return HLTask对象数组
 */
- (NSArray <HLTask *>*)requestTasks;

@optional
/**
 task 上传、下载等长时间执行的Progress进度
 
 @param progress 进度
 @param task 调用的任务
 */
- (void)requestProgress:(nullable NSProgress *)progress atTask:(nullable HLTask *)task;

/**
 请求成功的回调
 
 @param responseObject 回调对象
 @param task 调用的任务
 */
- (void)requestSucessWithResponseObject:(nullable id)responseObject atTask:(nullable HLTask *)task;

/**
 请求失败的回调
 
 @param error 错误对象
 @param task 调用的任务
 */
- (void)requestFailureWithResponseError:(nullable NSError *)error atTask:(nullable HLTask *)task;
@end

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

// 发送Task请求
- (void)sendGroup:(HLTaskGroup *)taskGroup;

// 取消Task，如果该请求已经发送或者正在发送，则不保证一定可以取消
- (void)cancelGroup:(HLTaskGroup *)taskGroup;

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

// 发送Task请求
+ (void)sendGroup:(HLTaskGroup *)taskGroup;

// 取消Task，如果该请求已经发送或者正在发送，则不保证一定可以取消
+ (void)cancelGroup:(HLTaskGroup *)taskGroup;

// 注册网络请求监听者
+ (void)registerResponseObserver:(id<HLTaskResponseProtocol>)observer;

// 删除网络请求监听者
+ (void)removeResponseObserver:(id<HLTaskResponseProtocol>)observer;
@end
NS_ASSUME_NONNULL_END
