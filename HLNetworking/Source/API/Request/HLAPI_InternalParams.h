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
@property (nonatomic, strong) Class objClz;
@property (nonatomic, assign) BOOL useDefaultParams;
@property (nonatomic, weak, nullable) id<HLAPIRequestDelegate> delegate;
@property (nonatomic, weak, nullable) id<HLObjReformerProtocol> objReformerDelegate;
@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) HLSecurityPolicyConfig *securityPolicy;
@property (nonatomic, assign) HLRequestMethodType requestMethodType;
@property (nonatomic, assign) HLRequestSerializerType requestSerializerType;
@property (nonatomic, assign) HLResponseSerializerType responseSerializerType;
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, copy) NSDictionary<NSString *, NSObject *> *parameters;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *header;
@property (nonatomic, copy) NSSet *accpetContentTypes;
@property (nonatomic, copy) NSString *cURL;

@property (nonatomic, copy, nullable) void (^apiSuccessHandler)(_Nonnull id responseObject);
@property (nonatomic, copy, nullable) void (^apiFailureHandler)(NSError * _Nullable error);
@property (nonatomic, copy, nullable) void (^apiProgressHandler)(NSProgress * _Nullable progress);
@property (nonatomic, copy, nullable) void (^apiRequestConstructingBodyBlock)(id<HLMultipartFormDataProtocol> _Nonnull formData);
@end
NS_ASSUME_NONNULL_END
