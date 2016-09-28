//
//  HLAPIBatchRequests.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HLAPI;
@class HLAPIBatchRequests;

@protocol HLAPIBatchRequestsProtocol <NSObject>

/**
 *  Batch Requests 全部调用完成之后调用
 *
 *  @param batchApis batchApis
 */
- (void)batchAPIRequestsDidFinished:(HLAPIBatchRequests * _Nonnull)batchApis;

@end

@interface HLAPIBatchRequests : NSObject

/**
 *  Batch 执行的API Requests 集合
 */
@property (nonatomic, strong, readonly, nullable) NSMutableSet *apiRequestsSet;

/**
 *  Batch Requests 执行完成之后调用的delegate
 */
@property (nonatomic, weak, nullable) id<HLAPIBatchRequestsProtocol> delegate;


/**
 将API 加入到BatchRequest Set 集合中

 @param api 新加入的请求
 */
- (void)addAPIRequest:(HLAPI * _Nonnull)api;

/**
 *  将带有API集合的Sets 赋值
 *
 *  @param apis 新加入的请求Set
 */
- (void)addBatchAPIRequests:(nonnull NSSet *)apis;

/**
 *  开启API 请求
 */
- (void)start;

@end
