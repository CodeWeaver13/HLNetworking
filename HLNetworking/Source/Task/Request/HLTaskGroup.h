//
//  HLTaskGroup.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/7.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HLTask;
@class HLTaskGroup;
NS_ASSUME_NONNULL_BEGIN
@protocol HLTaskGroupProtocol <NSObject>
// Requests 全部调用完成之后调用
- (void)apiGroupAllDidFinished:(nonnull HLTaskGroup *)apiGroup;
@end

typedef NS_ENUM(NSUInteger, HLAPIGroupMode) {
    HLAPIGroupModeBatch,
    HLAPIGroupModeChian
};
@interface HLTaskGroup : NSObject

// 请求组类型
@property (nonatomic, assign, readonly) HLAPIGroupMode groupMode;

@property (nonatomic, assign) NSUInteger maxRequestCount;

// 自定义的同步请求所在的串行队列
@property (nonatomic, strong, readonly) dispatch_queue_t customQueue;

// Group 内 api 执行完成之后调用的delegate
@property (nonatomic, weak, nullable) id<HLTaskGroupProtocol> delegate;

// 请使用manager或sharedManager
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// 返回一个新的manager对象
+ (instancetype)groupWithMode:(HLAPIGroupMode)mode;

// 加入到group集合中
- (void)add:(nonnull HLTask *)task;

// 将带有API集合的Array 赋值
- (void)addAPIs:(nonnull NSArray<HLTask *> *)tasks;

// 开启队列请求
- (void)start;

// 取消所有请求
- (void)cancel;

// 设置组GCD队列
- (dispatch_queue_t)setupGroupQueue:(NSString *)queueName;

#pragma mark - 遍历方法

@property (readonly) NSUInteger count;

- (void)enumerateObjectsUsingBlock:(void (^)(HLTask *task, NSUInteger idx, BOOL * stop))block;

- (nonnull NSEnumerator*)objectEnumerator;

- (nonnull id)objectAtIndexedSubscript:(NSUInteger)idx;
@end
NS_ASSUME_NONNULL_END
