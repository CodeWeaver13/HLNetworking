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

@protocol HLAPIChainRequestsProtocol <NSObject>
/**
 *  Chain Requests 全部调用完成之后调用
 *
 *  @param chainApis chainApis集合
 */
- (void)chainRequestsAllDidFinished:(nonnull HLAPIChainRequests *)chainApis;

@end

@interface HLAPIChainRequests : NSObject<NSFastEnumeration>

@property (nonatomic, assign, readonly)BOOL isCancel;

/**
 *  Sync Batch Requests 执行完成之后调用的delegate
 */
@property (nonatomic, weak, nullable) id<HLAPIChainRequestsProtocol> delegate;


/**
 将API 加入到chainBatchRequest Array 集合中
 
 @param api 新加入的请求
 */
- (void)add:(nonnull HLAPI *)api;

/**
 *  将带有API集合的Array 赋值
 *
 *  @param apis 新加入的请求Array
 */
- (void)addAPIs:(nonnull NSArray<HLAPI *> *)apis;

/**
 *  开启API 请求
 */
- (void)start;

/**
 取消请求所有请求
 */
- (void)cancel;

#pragma mark - 遍历方法

@property (readonly) NSUInteger count;

- (void)enumerateObjectsUsingBlock:(void (^_Nonnull)(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop))block;

- (nonnull NSEnumerator*)objectEnumerator;

- (nonnull id)objectAtIndexedSubscript:(NSUInteger)idx;
@end
