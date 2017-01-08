//
//  HLAPI_InternalParams.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/10/2.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLAPI.h"
NS_ASSUME_NONNULL_BEGIN
@interface HLAPI ()
// readOnly property
@property (nonatomic, strong, nullable) Class objClz;
@property (nonatomic, assign) BOOL useDefaultParams;
@property (nonatomic, weak, nullable) id<HLAPIRequestDelegate> delegate;
@property (nonatomic, weak, nullable) id<HLObjReformerProtocol> objReformerDelegate;
@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy, nullable) NSString *path;
@property (nonatomic, strong) HLSecurityPolicyConfig *securityPolicy;
@property (nonatomic, assign) HLRequestMethodType requestMethodType;
@property (nonatomic, assign) HLRequestSerializerType requestSerializerType;
@property (nonatomic, assign) HLResponseSerializerType responseSerializerType;
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSObject *> *parameters;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *header;
@property (nonatomic, copy) NSSet *accpetContentTypes;
@property (nonatomic, copy, nullable) NSString *cURL;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong, nullable) dispatch_queue_t queue;

@property (nonatomic, copy, nullable) HLSuccessBlock apiSuccessHandler;
@property (nonatomic, copy, nullable) HLFailureBlock apiFailureHandler;
@property (nonatomic, copy, nullable) HLProgressBlock apiProgressHandler;
@property (nonatomic, copy, nullable) HLRequestConstructingBodyBlock apiRequestConstructingBodyBlock;
@property (nonatomic, copy, nullable) HLDebugBlock apiDebugHandler;
@end
NS_ASSUME_NONNULL_END
