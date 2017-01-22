//
//  HLAPIManager.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/17.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLNetworkConst.h"

// 判断当前是否为审核版本
FOUNDATION_EXPORT BOOL HLJudgeVersion(void);
// 设置是否为审核版本
FOUNDATION_EXPORT void HLJudgeVersionSwitch(BOOL isR);

@protocol HLNetworkErrorProtocol;
@protocol HLAPIResponseDelegate;
@class HLNetworkConfig;
@class HLAPI;
@class HLAPIGroup;
@class HLDebugMessage;
NS_ASSUME_NONNULL_BEGIN

@protocol HLAPIResponseDelegate <NSObject>

/**
 快速返回必须的apis
 
 @param ... apis
 @return 必要的APIs集合
 */
#define HLObserverAPIs(...) \
- (NSArray <HLAPI *>*)requestAPIs { \
return [NSArray arrayWithObjects:__VA_ARGS__, nil];; \
}

@required
/**
 返回必须的apis
 
 @return 必要的APIs集合
 */
- (NSArray <HLAPI *>*)requestAPIs;

@optional
/**
 请求成功的回调
 
 @param responseObject 回调对象
 @param api 调用的api
 */
- (void)requestSucessWithResponseObject:(nonnull id)responseObject atAPI:(HLAPI *)api;

/**
 请求失败的回调
 
 @param error 错误对象
 @param api 调用的api
 */
- (void)requestFailureWithResponseError:(nullable NSError *)error atAPI:(HLAPI *)api;

/**
 api 上传、下载等长时间执行的Progress进度
 
 @param progress 进度
 @param api 调用的api
 */
- (void)requestProgress:(nullable NSProgress *)progress atAPI:(HLAPI *)api;
@end

@interface HLAPIManager : NSObject

@property (nonatomic, strong, readonly) HLNetworkConfig *config;

// 请使用manager或sharedManager
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// 返回一个新的manager对象
+ (HLAPIManager *)manager;

// 配置设置
- (void)setupConfig:(void(^)(HLNetworkConfig *config))configBlock;

/**
 发送API请求
 默认为manager内置队列
 
 @param api 要发送的api
 */
- (void)send:(HLAPI *)api;

/**
 发送一组请求
 
 @param group 请求组
 */
- (void)sendGroup:(HLAPIGroup *)group;

/**
 取消API请求
 如果该请求已经发送或者正在发送，则不保证一定可以取消，但会将Block回落点置空，delegate正常回调
 默认为manager内置队列
 
 @param api 要取消的api
 */
- (void)cancel:(HLAPI *)api;

/**
 取消API请求
 如果该请求已经发送或者正在发送，则不保证一定可以取消，但会将Block回落点置空，delegate正常回调
 默认为manager内置队列
 
 @param group 要取消的api组
 */
- (void)cancelGroup:(HLAPIGroup *)group;

/**
 移除网络请求监听者

 @param observer 监听者
 */
- (void)registerResponseObserver:(id<HLAPIResponseDelegate>)observer;

/**
 删除网络请求监听者
 
 @param observer 监听者
 */
- (void)removeResponseObserver:(id<HLAPIResponseDelegate>)observer;

/**
 添加网络传输错误时的监控observer

 @param observer 遵循HLNetworkErrorProtocol的observer
 */
- (void)registerErrorObserver:(id<HLNetworkErrorProtocol>)observer;

/**
 删除网络传输错误时的监控observer

 @param observer 遵循HLNetworkErrorProtocol的observer
 */
- (void)removeErrorObserver:(id<HLNetworkErrorProtocol>)observer;

#pragma mark - sharedManager类方法

#pragma mark - 初始化方法
// 默认单例
+ (HLAPIManager *)sharedManager;

// 为sharedManager单例配置设置
+ (void)setupConfig:(void(^)(HLNetworkConfig *config))configBlock;

#pragma mark - API操作
/**
 使用sharedManager单例发送API
 默认在内置队列
 
 @param api 需要发送的API
 */
+ (void)send:(HLAPI *)api;

/**
 使用sharedManager取消API请求
 如果该请求已经发送或者正在发送，则不保证一定可以取消，但会将Block回落点置空，delegate正常回调
 默认在内置队列
 
 @param api 要取消的api
 */
+ (void)cancel:(HLAPI *)api;

#pragma mark - API集合请求
/**
 使用sharedManager发送一系列API请求

 @param group 待发送的API请求集合
 */
+ (void)sendGroup:(HLAPIGroup *)group;

/**
 使用sharedManager取消API请求组
 如果该请求已经发送或者正在发送，则不保证一定可以取消，但会将Block回落点置空，delegate正常回调
 默认为manager内置队列
 
 @param group 要取消的api组
 */
+ (void)cancelGroup:(HLAPIGroup *)group;

#pragma mark - 注册/销毁网络消息监听
/**
 使用sharedManager移除网络请求监听者
 
 @param observer 监听者
 */
+ (void)registerResponseObserver:(id<HLAPIResponseDelegate>)observer;

/**
 使用sharedManager删除网络请求监听者
 
 @param observer 监听者
 */
+ (void)removeResponseObserver:(id<HLAPIResponseDelegate>)observer;

/**
 使用sharedManager添加网络传输错误时的监控observer

 @param observer 遵循HLNetworkErrorProtocol的observer
 */
+ (void)registerErrorObserver:(id<HLNetworkErrorProtocol>)observer;

/**
 使用sharedManager删除网络传输错误时的监控observer

 @param observer 遵循HLNetworkErrorProtocol的observer
 */
+ (void)removeErrorObserver:(id<HLNetworkErrorProtocol>)observer;

#pragma mark - reachability相关
// 当前reachability状态
@property (nonatomic, assign, readonly) HLReachabilityStatus reachabilityStatus;
// 当前是否可访问网络
@property (nonatomic, assign, readonly, getter = isReachable) BOOL reachable;
// 当前是否使用数据流量访问网络
@property (nonatomic, assign, readonly, getter = isReachableViaWWAN) BOOL reachableViaWWAN;
// 当前是否使用WiFi访问网络
@property (nonatomic, assign, readonly, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

// 通过sharedMager单例，获取当前reachability状态
+ (HLReachabilityStatus)reachabilityStatus;
// 通过sharedMager单例，获取当前是否可访问网络
+ (BOOL)isReachable;
// 通过sharedMager单例，获取当前是否使用数据流量访问网络
+ (BOOL)isReachableViaWWAN;
// 通过sharedMager单例，获取当前是否使用WiFi访问网络
+ (BOOL)isReachableViaWiFi;

// 开启默认reachability监视器，block返回状态
+ (void)listening:(HLReachabilityBlock)listener;
// 默认reachability监视器停止监听
+ (void)stopListening;

// 监听给定的域名是否可以访问，block内返回状态
- (void)listeningWithDomain:(NSString *)domain listeningBlock:(HLReachabilityBlock)listener;
// 停止给定域名的网络状态监听
- (void)stopListeningWithDomain:(NSString *)domain;
@end
NS_ASSUME_NONNULL_END
