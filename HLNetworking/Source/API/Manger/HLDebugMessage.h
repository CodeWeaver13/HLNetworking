//
//  HLDebugMessage.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HLAPI;

@interface HLDebugMessage : NSObject
#pragma mark - DebugKey
// 获取NSURLSessionTask
@property (nonatomic, strong, readonly)NSURLSessionTask *sessionTask;
// 获取HLAPI
@property (nonatomic, strong, readonly)HLAPI *api;
// 获取NSError
@property (nonatomic, strong, readonly)NSError *error;
// 获取NSURLRequest
@property (nonatomic, strong, readonly)NSURLRequest *originRequest;
// 获取NSURLRequest
@property (nonatomic, strong, readonly)NSURLRequest *currentRequest;
// 获取NSURLResponse
@property (nonatomic, strong, readonly)NSURLResponse *response;
// 执行的队列名
@property (nonatomic, strong, readonly)dispatch_queue_t queueName;

- (instancetype)initWithDict:(NSDictionary *)dict;
@end
