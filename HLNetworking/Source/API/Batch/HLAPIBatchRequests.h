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

// 已经被全部取消
@property (nonatomic, assign, readonly)BOOL isCancel;

// Batch 执行的API Requests 集合
@property (nonatomic, strong, readonly, nullable) NSMutableSet<HLAPI *> *apiSet;

// Batch Requests 执行完成之后调用的delegate
@property (nonatomic, weak, nullable) id<HLAPIBatchRequestsProtocol> delegate;

// 将API 加入到BatchRequest Set 集合中
- (void)add:(HLAPI * _Nonnull)api;

// 将带有API集合的Sets 赋值
- (void)addAPIs:(nonnull NSSet<HLAPI *> *)apis;

// 开启API 请求
- (void)start;

// 取消请求所有请求
- (void)cancel;
@end
