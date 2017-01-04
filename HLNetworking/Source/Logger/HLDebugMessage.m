//
//  HLDebugMessage.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLDebugMessage.h"

HLDebugKey const kHLSessionTaskDebugKey = @"kHLSessionTaskDebugKey";
HLDebugKey const kHLAPIDebugKey = @"kHLAPIDebugKey";
HLDebugKey const kHLErrorDebugKey = @"kHLErrorDebugKey";
HLDebugKey const kHLOriginalRequestDebugKey = @"kHLOriginalRequestDebugKey";
HLDebugKey const kHLCurrentRequestDebugKey = @"kHLCurrentRequestDebugKey";
HLDebugKey const kHLResponseDebugKey = @"kHLResponseDebugKey";
HLDebugKey const kHLQueueDebugKey = @"kHLQueueDebugKey";

@interface HLDebugMessage ()
// 获取NSURLSessionTask
@property (nonatomic, strong, readwrite)NSURLSessionTask *sessionTask;
// 获取HLAPI
@property (nonatomic, strong, readwrite)id requestObject;
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
        _requestObject = dict[kHLAPIDebugKey];
        _error = dict[kHLErrorDebugKey];
        _originRequest = dict[kHLOriginalRequestDebugKey];
        _currentRequest = dict[kHLCurrentRequestDebugKey];
        _response = dict[kHLResponseDebugKey];
        _queueName = dict[kHLQueueDebugKey];
    }
    return self;
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"\n****************Debug Message Start****************\n"];
    [desc appendFormat:@"RequestObject : %@\n", self.requestObject ?: @"无参数"];
    [desc appendFormat:@"SessionTask : %@\n", self.sessionTask ?: @"无参数"];
    [desc appendFormat:@"OriginRequest : %@\n", self.originRequest ?: @"无参数"];
    [desc appendFormat:@"CurrentRequest : %@\n", self.currentRequest ?: @"无参数"];
    [desc appendFormat:@"Response : %@\n", self.response ?: @"无参数"];
    [desc appendFormat:@"Error : %@\n", self.error ?: @"无参数"];
    [desc appendFormat:@"Queue : %@", self.queueName ?: @"无参数"];
    [desc appendString:@"\n****************Debug Message End****************\n"];
    return desc;
}

- (NSString *)debugDescription {
    return self.description;
}

@end
