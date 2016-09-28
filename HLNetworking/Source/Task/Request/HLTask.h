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
@property (nonatomic, copy, readonly) NSString *resumePath;
@property (nonatomic, weak, nullable, readonly) id<HLTaskRequestDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *taskURL;
@property (nonatomic, copy, readonly) NSString *baseURL;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, assign, readonly)NSTimeInterval timeoutInterval;
@property (nonatomic, assign, readonly)NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, strong, readonly)HLSecurityPolicyConfig *securityPolicy;
@property (nonatomic, assign, readonly)HLRequestTaskType requestTaskType;

/**
 设置HLAPI的requestDelegate
 */
- (HLTask *(^)(id<HLTaskRequestDelegate> delegate))setDelegate;

/**
 taskURL
 如果设置了taskURL，则baseURL无效
 */
- (HLTask *(^)(NSString *taskURL))setTaskURL;

/**
 *  baseURL
 *  注意：如果Task子类有设定baseURL, 则 Configuration 里的baseURL不起作用
 *  即： Task里的baseURL 优先级更高
 */
- (HLTask *(^)(NSString *baseURL))setBaseURL;

/**
 urlQuery
 即baseURL后的地址
 */
- (HLTask *(^)(NSString *path))setPath;

/**
 *  filePath
 *  保存或者读取的本地文件路径
 */
- (HLTask *(^)(NSString *filePath))setFilePath;

#pragma mark - functory method
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
@end
NS_ASSUME_NONNULL_END
