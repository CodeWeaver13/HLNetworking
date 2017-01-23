//
//  HLNetworkManager.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLNetworkConst.h"

@class HLNetworkConfig;
@class HLURLRequest;
@class HLRequestGroup;
@protocol HLNetworkResponseDelegate;

// 判断当前是否为审核版本
FOUNDATION_EXPORT inline BOOL HLJudgeVersion(void);
// 设置是否为审核版本
FOUNDATION_EXPORT inline void HLJudgeVersionSwitch(BOOL isR);

NS_ASSUME_NONNULL_BEGIN
@interface HLNetworkManager : NSObject

#pragma mark - property
@property (nonatomic, strong, readonly) HLNetworkConfig *config;
+ (HLNetworkConfig *)config;

#pragma mark - initialize method
// 请使用manager或sharedManager
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
// 返回一个新的manager对象
+ (instancetype)manager;
// 返回单例
+ (instancetype)sharedManager;
// 配置设置
+ (void)setupConfig:(void(^)(HLNetworkConfig *config))configBlock;
- (void)setupConfig:(void(^)(HLNetworkConfig *config))configBlock;

#pragma mark - process
// 发送API请求，默认为manager内置队列
+ (void)send:(__kindof HLURLRequest *)request;
- (void)send:(__kindof HLURLRequest *)request;
// 发送一组请求
+ (void)sendGroup:(HLRequestGroup *)group;
- (void)sendGroup:(HLRequestGroup *)group;
// 取消API请求，如果该请求已经发送或者正在发送，则不保证一定可以取消，但会将Block回落点置空，delegate正常回调，默认为manager内置队列
+ (void)cancel:(__kindof HLURLRequest *)request;
- (void)cancel:(__kindof HLURLRequest *)request;
// 取消API请求，如果该请求已经发送或者正在发送，则不保证一定可以取消，但会将Block回落点置空，delegate正常回调，默认为manager内置队列
+ (void)cancelGroup:(HLRequestGroup *)group;
- (void)cancelGroup:(HLRequestGroup *)group;
// 恢复Task
+ (void)resume:(__kindof HLURLRequest *)request;
- (void)resume:(__kindof HLURLRequest *)request;
// 暂停Task
+ (void)pause:(__kindof HLURLRequest *)request;
- (void)pause:(__kindof HLURLRequest *)request;
// 注册网络请求监听者
+ (void)registerResponseObserver:(id<HLNetworkResponseDelegate>)observer;
- (void)registerResponseObserver:(id<HLNetworkResponseDelegate>)observer;
// 删除网络请求监听者
+ (void)removeResponseObserver:(id<HLNetworkResponseDelegate>)observer;
- (void)removeResponseObserver:(id<HLNetworkResponseDelegate>)observer;

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

#pragma mark - manager监听代理
@protocol HLNetworkResponseDelegate <NSObject>
// 快速设置需要监听的task对象
#define HLObserverRequests(...) \
- (NSArray <__kindof HLURLRequest *>* _Nonnull)observerRequests { \
return [NSArray arrayWithObjects:__VA_ARGS__, nil]; \
}

@required
// 设置需要监听的task对象
- (NSArray <HLURLRequest *>*)observerRequests;

@optional
// task 上传、下载等长时间执行的Progress进度
- (void)requestProgress:(nullable NSProgress *)progress atRequest:(nullable HLURLRequest *)request;
// 请求成功的回调
- (void)requestSucess:(nullable id)responseObject atRequest:(nullable HLURLRequest *)request;
// 请求失败的回调
- (void)requestFailure:(nullable NSError *)error atRequest:(nullable HLURLRequest *)request;
@end
NS_ASSUME_NONNULL_END
