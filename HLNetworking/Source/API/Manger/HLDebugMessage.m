//
//  HLDebugMessage.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLDebugMessage.h"
#import "HLAPI.h"

@interface HLDebugMessage ()
// 获取NSURLSessionTask
@property (nonatomic, strong, readwrite)NSURLSessionTask *sessionTask;
// 获取HLAPI
@property (nonatomic, strong, readwrite)HLAPI *api;
// 获取NSError
@property (nonatomic, strong, readwrite)NSError *error;
// 获取NSURLRequest
@property (nonatomic, strong, readwrite)NSURLRequest *originRequest;
// 获取NSURLRequest
@property (nonatomic, strong, readwrite)NSURLRequest *currentRequest;
// 获取NSURLResponse
@property (nonatomic, strong, readwrite)NSURLResponse *response;
// 执行的队列名
@property (nonatomic, strong, readwrite)dispatch_queue_t queueName;
@end

@implementation HLDebugMessage

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _sessionTask = dict[kHLSessionTaskDebugKey];
        _api = dict[kHLAPIDebugKey];
        _error = dict[kHLErrorDebugKey];
        _originRequest = dict[kHLOriginalRequestDebugKey];
        _currentRequest = dict[kHLCurrentRequestDebugKey];
        _response = dict[kHLResponseDebugKey];
        _queueName = dict[kHLQueueDebugKey];
    }
    return self;
}

@end
