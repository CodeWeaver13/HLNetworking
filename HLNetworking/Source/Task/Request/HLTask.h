//
//  HLTask.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/25.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLNetworkConst.h"
@class HLTask;
@class HLSecurityPolicyConfig;

NS_ASSUME_NONNULL_BEGIN
@protocol HLTaskRequestDelegate <NSObject>
@optional
// 请求将要发出
- (void)requestWillBeSentWithTask:(HLTask *)task;
// 请求已经发出
- (void)requestDidSentWithTask:(HLTask *)task;
@end
@interface HLTask : NSObject<NSCopying>
@property (nonatomic, copy, nullable, getter=customURL, readonly) NSString *cURL;
@property (nonatomic, copy, readonly) NSString *baseURL;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, copy, readonly) NSString *resumePath;

// 设置HLAPI的requestDelegate
- (HLTask *(^)(id<HLTaskRequestDelegate> delegate))setDelegate;

// 自定义的RequestUrl，该参数会无视任何baseURL的设置，优先级最高
- (HLTask *(^)(NSString *taskURL))setCustomURL;

// 设置API的baseURL，该参数会覆盖config中的baseURL
- (HLTask *(^)(NSString *baseURL))setBaseURL;

// urlQuery即baseURL后的地址
- (HLTask *(^)(NSString *path))setPath;

// 设置下载或者上传的本地文件路径
- (HLTask *(^)(NSString *filePath))setFilePath;

// 设置安全策略
- (HLTask* (^)(HLSecurityPolicyConfig *apiSecurityPolicy))setSecurityPolicy;

// 设置task的类型（上传/下载）
- (HLTask* (^)(HLRequestTaskType requestTaskType))setTaskType;

#pragma mark - handler block function
/**
 API完成后的成功回调
 写法：
 .success(^(id obj) {
 dosomething
 })
 */
- (HLTask *(^)(HLSuccessBlock))success;

/**
 API完成后的失败回调
 写法：
 .failure(^(NSError *error) {
 
 })
 */
- (HLTask *(^)(HLFailureBlock))failure;

/**
 API上传、下载等长时间执行的Progress进度
 写法：
 .progress(^(NSProgress *proc){
 NSLog(@"当前进度：%@", proc);
 })
 */
- (HLTask *(^)(HLProgressBlock))progress;

#pragma mark - functory method
// 请使用task
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (nullable instancetype)task;

#pragma mark - Process

/**
 *  开启Task 请求
 */
- (HLTask *)start;

/**
 *  取消Task 请求
 */
- (HLTask *)cancel;

/**
 继续Task
 */
- (HLTask *)resume;

/**
 暂停Task
 */
- (HLTask *)pause;

- (NSString *)hashKey;
@end
NS_ASSUME_NONNULL_END
