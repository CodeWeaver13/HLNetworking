//
//  HLDebugMessage.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLURLResponse.h"
typedef NSString *HLDebugKey;

@interface HLDebugMessage : NSObject
#pragma mark - DebugKey
// 获取NSURLSessionTask
FOUNDATION_EXPORT HLDebugKey const kHLSessionTaskDebugKey;
// 获取HLAPI
FOUNDATION_EXPORT HLDebugKey const kHLRequestDebugKey;
// 获取NSURLResponse
FOUNDATION_EXPORT HLDebugKey const kHLResponseDebugKey;
// 获取执行的队列名
FOUNDATION_EXPORT HLDebugKey const kHLQueueDebugKey;

// 请求对象，HLAPI或HLTask
@property (nonatomic, strong, readonly)id requestObject;
// 获取NSURLSessionTask
@property (nonatomic, strong, readonly)NSURLSessionTask *sessionTask;
// 获取RequestObject
@property (nonatomic, strong, readonly)HLURLResponse *response;
// 执行的队列名
@property (nonatomic, strong, readonly)dispatch_queue_t queueName;

- (instancetype)initWithDict:(NSDictionary *)dict;
@end
