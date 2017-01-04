//
//  HLAPISyncBatchRequests.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/24.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HLAPI;
@class HLAPIChainRequests;
NS_ASSUME_NONNULL_BEGIN
@protocol HLAPIChainRequestsProtocol <NSObject>
// Chain Requests 全部调用完成之后调用
- (void)chainRequestsAllDidFinished:(nonnull HLAPIChainRequests *)chainApis;

@end

@interface HLAPIChainRequests : NSObject<NSFastEnumeration>

// 自定义的同步请求所在的串行队列
@property (nonatomic, strong, readonly) dispatch_queue_t customChainQueue;

// 已经被全部取消
@property (nonatomic, assign, readonly) BOOL isCancel;

// Chain Requests 执行完成之后调用的delegate
@property (nonatomic, weak, nullable) id<HLAPIChainRequestsProtocol> delegate;

// 加入到chainBatchRequest Array 集合中
- (void)add:(nonnull HLAPI *)api;

// 将带有API集合的Array 赋值
- (void)addAPIs:(nonnull NSArray<HLAPI *> *)apis;

// 开启队列请求
- (void)start;

// 取消所有请求
- (void)cancel;

- (dispatch_queue_t)setupChainQueue:(NSString *)queueName;

#pragma mark - 遍历方法

@property (readonly) NSUInteger count;

- (void)enumerateObjectsUsingBlock:(void (^)(HLAPI *api, NSUInteger idx, BOOL * stop))block;

- (nonnull NSEnumerator*)objectEnumerator;

- (nonnull id)objectAtIndexedSubscript:(NSUInteger)idx;
@end
NS_ASSUME_NONNULL_END
