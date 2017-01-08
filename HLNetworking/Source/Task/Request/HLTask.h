//
//  HLTask.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/25.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLTaskType.h"
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
@interface HLTask : NSObject
@property (nonatomic, copy, readonly) NSString *taskURL;
@property (nonatomic, copy, readonly) NSString *baseURL;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, copy, readonly) NSString *resumePath;

// 设置HLAPI的requestDelegate
- (HLTask *(^)(id<HLTaskRequestDelegate> delegate))setDelegate;

// 自定义的RequestUrl，该参数会无视任何baseURL的设置，优先级最高
- (HLTask *(^)(NSString *taskURL))setTaskURL;

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
