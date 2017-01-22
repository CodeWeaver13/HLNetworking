//
//  HLDebugMessage.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLDebugMessage.h"
#import "HLNetworkEngine.h"

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
@property (nonatomic, copy, readwrite)NSString *queueName;
// 生成时间
@property (nonatomic, copy, readwrite) NSString *timeString;
@end

@implementation HLDebugMessage

- (instancetype)initWithRequest:(id)requestObject andResult:(id)resultObject andError:(NSError *)error andQueueName:(NSString *)queueName {
    self = [super init];
    if (self) {
        NSDateFormatter *myFormatter = [[NSDateFormatter alloc] init];
        [myFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        _timeString = [myFormatter stringFromDate:[NSDate date]];
        
        NSString *hashKey = [requestObject performSelector:@selector(hashKey)];
        id sessionTask = [[HLNetworkEngine sharedEngine] requestByIdentifier: hashKey];
        id request = [NSNull null];
        id requestId = [NSNull null];
        
        if ([requestObject isKindOfClass:[NSURLSessionTask class]]) {
            request = [sessionTask currentRequest];
        }
        if ([requestObject hash]) {
            requestId = [NSNumber numberWithUnsignedInteger:[requestObject hash]];
        }
        // 生成response对象
        HLURLResult *result = [[HLURLResult alloc] initWithObject:resultObject andError:error];
        HLURLResponse *response = [[HLURLResponse alloc] initWithResult:result
                                                              requestId:requestId
                                                                request:request];
        _sessionTask = sessionTask;
        _requestObject = request;
        _response = response;
        _queueName = queueName;
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary <NSString *, id>*dictionary = [NSMutableDictionary dictionary];
    dictionary[@"Time"] = self.timeString;
    dictionary[@"RequestObject"] = [self.requestObject toDictionary];
    dictionary[@"Response"] = [self.response toDictionary];
    dictionary[@"SessionTask"] = [self.sessionTask description];
    dictionary[@"Queue"] = self.queueName;
    return dictionary;
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"\n****************Debug Message Start****************\n"];
    [desc appendFormat:@"Time : %@\n", self.timeString];
    [desc appendFormat:@"RequestObject : %@\n", self.requestObject ?: @"无参数"];
    [desc appendFormat:@"SessionTask : %@\n", self.sessionTask ?: @"无参数"];
    [desc appendFormat:@"Response : %@\n", self.response ?: @"无参数"];
    [desc appendFormat:@"Queue : %@", self.queueName ?: @"无参数"];
    [desc appendString:@"\n****************Debug Message End****************\n"];
    return desc;
}

- (NSString *)debugDescription {
    return self.description;
}

@end
