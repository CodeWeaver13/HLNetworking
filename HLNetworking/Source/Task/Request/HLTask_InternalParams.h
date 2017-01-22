//
//  HLTask_InternalParams.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/10/3.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLTask.h"
NS_ASSUME_NONNULL_BEGIN
@interface HLTask ()
@property (nonatomic, weak, nullable) id<HLTaskRequestDelegate> delegate;
@property (nonatomic, copy) NSString *cURL;
@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *resumePath;
@property (nonatomic, assign)NSTimeInterval timeoutInterval;
@property (nonatomic, assign)NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, strong)HLSecurityPolicyConfig *securityPolicy;
@property (nonatomic, assign)HLRequestTaskType requestTaskType;

@property (nonatomic, copy, nullable) HLSuccessBlock taskSuccessHandler;
@property (nonatomic, copy, nullable) HLFailureBlock taskFailureHandler;
@property (nonatomic, copy, nullable) HLProgressBlock taskProgressHandler;

@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong, nullable) dispatch_queue_t queue;
@end
NS_ASSUME_NONNULL_END
