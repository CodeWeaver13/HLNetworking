//
//  HLTaskResponseProtocol.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/29.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HLTask;

NS_ASSUME_NONNULL_BEGIN
@protocol HLTaskResponseProtocol <NSObject>
@required

/**
 用于返回需要监听的task对象

 @return HLTask对象数组
 */

#define HLTaskResponseDelegateRequestTasks(...) \
- (NSArray <HLTask *>* _Nonnull)requestTasks { \
    return @[ __VA_ARGS__ ]; \
}

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
- (void)requestSucessWithResponseObject:(nonnull id)responseObject atTask:(nullable HLTask *)task;

/**
 请求失败的回调

 @param error 错误对象
 @param task 调用的任务
 */
- (void)requestFailureWithResponseError:(nullable NSError *)error atTask:(nullable HLTask *)task;

@end
NS_ASSUME_NONNULL_END
