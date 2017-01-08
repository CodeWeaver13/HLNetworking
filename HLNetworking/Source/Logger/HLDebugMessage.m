//
//  HLDebugMessage.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLDebugMessage.h"

HLDebugKey const kHLSessionTaskDebugKey = @"kHLSessionTaskDebugKey";
HLDebugKey const kHLRequestDebugKey = @"kHLRequestDebugKey";
HLDebugKey const kHLResponseDebugKey = @"kHLResponseDebugKey";
HLDebugKey const kHLQueueDebugKey = @"kHLQueueDebugKey";

@interface HLDebugMessage ()
// 获取NSURLSessionTask
@property (nonatomic, strong, readwrite)NSURLSessionTask *sessionTask;
// 获取HLAPI
@property (nonatomic, strong, readwrite)id requestObject;
// 获取NSURLResponse
@property (nonatomic, strong, readwrite)HLURLResponse *response;
// 执行的队列名
@property (nonatomic, strong, readwrite)dispatch_queue_t queue;
// 生成时间
@property (nonatomic, copy) NSString *timeString;
@end

@implementation HLDebugMessage

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        NSDateFormatter *myFormatter = [[NSDateFormatter alloc] init];
        [myFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        _timeString = [myFormatter stringFromDate:[NSDate date]];
        _sessionTask = dict[kHLSessionTaskDebugKey];
        _requestObject = dict[kHLRequestDebugKey];
        _response = dict[kHLResponseDebugKey];
        _queue = dict[kHLQueueDebugKey];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary <NSString *, id>*dictionary = [NSMutableDictionary dictionary];
    dictionary[@"Time"] = self.timeString;
    dictionary[@"RequestObject"] = [self.requestObject toDictionary];
    dictionary[@"SessionTask"] = [self.sessionTask description];
    dictionary[@"Response"] = [self.response toDictionary];
    dictionary[@"Queue"] = [self.queue description];
    return dictionary;
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"\n****************Debug Message Start****************\n"];
    [desc appendFormat:@"Time : %@\n", self.timeString];
    [desc appendFormat:@"RequestObject : %@\n", self.requestObject ?: @"无参数"];
    [desc appendFormat:@"SessionTask : %@\n", self.sessionTask ?: @"无参数"];
    [desc appendFormat:@"Response : %@\n", self.response ?: @"无参数"];
    [desc appendFormat:@"Queue : %@", self.queue ?: @"无参数"];
    [desc appendString:@"\n****************Debug Message End****************\n"];
    return desc;
}

- (NSString *)debugDescription {
    return self.description;
}

@end
