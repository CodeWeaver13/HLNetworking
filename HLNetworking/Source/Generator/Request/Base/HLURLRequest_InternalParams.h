//
//  HLURLRequest_InternalParams.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLURLRequest.h"
NS_ASSUME_NONNULL_BEGIN
@interface HLURLRequest ()
@property (nonatomic, weak, nullable) id<HLURLRequestDelegate> delegate;
@property (nonatomic, copy) NSString *cURL;
@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign)NSTimeInterval timeoutInterval;
@property (nonatomic, assign)NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, strong)HLSecurityPolicyConfig *securityPolicy;

@property (nonatomic, copy, nullable) HLSuccessBlock successHandler;
@property (nonatomic, copy, nullable) HLFailureBlock failureHandler;
@property (nonatomic, copy, nullable) HLProgressBlock progressHandler;
@property (nonatomic, copy, nullable) HLDebugBlock debugHandler;

@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong, nullable) dispatch_queue_t queue;
@property (nonatomic, strong, nullable) NSLock *lock;
@end
NS_ASSUME_NONNULL_END
