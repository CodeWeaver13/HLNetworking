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
 *  Batch Requests 全部调用完成之后调用
 *
 *  @param batchApis batchApis
 */
- (void)chainRequestsAllDidFinished:(nonnull HLAPIChainRequests *)batchApis;

@end

@interface HLAPIChainRequests : NSObject


@property (nonatomic, assign, readonly)BOOL isCancel;
/**
 *  Sync Batch 执行的API Requests 集合
 */
@property (nonatomic, strong, readonly, nullable) NSMutableArray *apiRequestsArray;

/**
 *  Sync Batch Requests 执行完成之后调用的delegate
 */
@property (nonatomic, weak, nullable) id<HLAPIChainRequestsProtocol> delegate;


/**
 将API 加入到SyncBatchRequest Array 集合中
 
 @param api 新加入的请求
 */
- (void)addAPIRequest:(nonnull HLAPI *)api;

/**
 *  将带有API集合的Array 赋值
 *
 *  @param apis 新加入的请求Array
 */
- (void)addChainAPIRequests:(nonnull NSArray<HLAPI *> *)apis;

/**
 *  开启API 请求
 */
- (void)start;

/**
 取消请求所有请求
 */
- (void)cancel;
@end
