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

@property (nonatomic, strong, nonnull) HLNetworkConfig *config;

+ (nonnull HLTaskManager *)shared;

@property (nonatomic, weak, nullable) id<HLTaskResponseProtocol> responseDelegate;

/**
 *  发送API请求
 *
 *  @param task 要发送的task
 */
- (void)sendTaskRequest:(nonnull HLTask *)task;

/**
 *  取消API请求
 *
 *  @description
 *      如果该请求已经发送或者正在发送，则无法取消
 *
 *  @param task 要取消的task
 */
- (void)cancelTaskRequest:(nonnull HLTask *)task;

/**
 暂停API请求
 
 @param task 要暂停的请求
 */
- (void)resumeTaskRequest:(nonnull HLTask *)task;

/**
 暂停API请求

 @param task 要暂停的请求
 */
- (void)pauseTaskRequest:(nonnull HLTask *)task;
@end
NS_ASSUME_NONNULL_END
