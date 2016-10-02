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
@property (nonatomic, copy) NSString *taskURL;
@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *resumePath;
@property (nonatomic, assign)NSTimeInterval timeoutInterval;
@property (nonatomic, assign)NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, strong)HLSecurityPolicyConfig *securityPolicy;
@property (nonatomic, assign)HLRequestTaskType requestTaskType;
@end
NS_ASSUME_NONNULL_END
