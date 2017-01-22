//
//  HLDebugMessage.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLURLResponse.h"
#import "NSNull+ToDictionary.h"

typedef NSString *HLDebugKey;

@interface HLDebugMessage : NSObject

// 请求对象，HLAPI或HLTask
@property (nonatomic, strong, readonly)id requestObject;
// 获取NSURLSessionTask
@property (nonatomic, strong, readonly)NSURLSessionTask *sessionTask;
// 获取RequestObject
@property (nonatomic, strong, readonly)HLURLResponse *response;
// 执行的队列名
@property (nonatomic, copy, readonly)NSString *queueName;
// 生成时间
@property (nonatomic, copy, readonly) NSString *timeString;

- (instancetype)initWithRequest:(id)requestObject andResult:(id)resultObject andError:(NSError *)error andQueueName:(NSString *)queueName;

- (NSDictionary *)toDictionary;
@end
