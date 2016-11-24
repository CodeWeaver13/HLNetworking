//
//  HLAPI.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/22.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLAPIType.h"
@class HLAPI;
@class HLSecurityPolicyConfig;
@protocol HLMultipartFormDataProtocol;
@protocol HLAPIRequestDelegate;
NS_ASSUME_NONNULL_BEGIN

#pragma mark - HLObjReformerProtocol
@protocol HLObjReformerProtocol <NSObject>
/**
 *  一般用来进行JSON -> Model 数据的转换工作
 *   返回的id，如果没有error，则为转换成功后的Model数据；
 *    如果有error， 则直接返回传参中的responseObject
 *
 *  @param responseObject 请求的返回
 *  @param error          请求的错误
 *
 *  @return 整理过后的请求数据
 */
- (nullable id)objReformerWithAPI:(HLAPI *)api andResponseObject:(id)responseObject andError:(NSError * _Nullable)error;
@end

#pragma mark - HLAPI

// 定义的Block
// 请求结果回调
typedef void(^ReObjBlock)(id __nullable responseObj);
// 请求失败回调
typedef void(^ReErrorBlock)(NSError * __nullable error);
// 请求进度回调
typedef void(^ProgressBlock)(NSProgress * __nullable progress);
// formData拼接回调
typedef void(^RequestConstructingBodyBlock)(id<HLMultipartFormDataProtocol> __nullable formData);

@interface HLAPI : NSObject
@property (nonatomic, assign, readonly) BOOL disableDefaultParams;
@property (nonatomic, strong, readonly) Class objClz;
@property (nonatomic, copy, readonly) NSString *baseURL;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, assign, readonly) NSTimeInterval timeoutInterval;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSObject *> *parameters;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *header;
@property (nonatomic, copy, readonly) NSSet *accpetContentTypes;
@property (nonatomic, copy, readonly) NSString *cURL;


- (HLAPI *(^)(BOOL disable))setDisableDefaultParams;

/**
 设置HLAPI对应的返回值类型
 */
- (HLAPI *(^)(NSString *clzName))setResponseClass;

/**
 设置HLAPI的requestDelegate
 */
- (HLAPI *(^)(id<HLAPIRequestDelegate> delegate))setDelegate;

/**
 进行JSON -> Model 数据的转换工作的Delegate
 如果设置了ReformerDelegate，则使用ReformerDelegate的obj解析，否则直接返回
 提供该Delegate主要用于Reformer的不相关代码的解耦工作
 
 param responseObject 请求回调对象
 param error          错误信息
 
 @return 请求结果数据
 */
- (HLAPI *(^)(id<HLObjReformerProtocol> delegate))setObjReformerDelegate;

/**
 *  baseURL
 *  注意：如果API子类有设定baseURL, 则 Configuration 里的baseURL不起作用
 *  即： API里的baseURL 优先级更高
 */
- (HLAPI *(^)(NSString *baseURL))setBaseURL;

/**
 urlQuery
 即baseURL后的地址
 */
- (HLAPI *(^)(NSString *path))setPath;

/**
 *  HTTPS 请求的Security策略
 *
 *  @return HTTPS证书验证策略
 */
- (HLAPI* (^)(HLSecurityPolicyConfig *apiSecurityPolicy))setSecurityPolicy;

/**
 *  请求的类型:GET, POST
 *  @default
 *   Post
 *
 *  @return HLRequestMethodType
 */
- (HLAPI* (^)(HLRequestMethodType requestMethodType))setMethod;

/**
 *  Request 序列化类型：JSON, HTTP, 见HLRequestSerializerType
 *  @default
 *   ResponseJSON
 *
 *  @return HLRequestSerializerTYPE
 */
- (HLAPI* (^)(HLRequestSerializerType requestSerializerType))setRequestType;

/**
 *  Response 序列化类型： JSON, HTTP
 *
 *  @return HLResponseSerializerType
 */
- (HLAPI* (^)(HLResponseSerializerType responseSerializerType))setResponseType;

/**
 *  HTTP 请求的Cache策略
 *  @default
 *   NSURLRequestUseProtocolCachePolicy
 *
 *  @return NSURLRequestCachePolicy
 */
- (HLAPI* (^)(NSURLRequestCachePolicy apiRequestCachePolicy))setCachePolicy;

/**
 *  HTTP 请求超时的时间
 *  @default
 *    API_REQUEST_TIME_OUT
 *
 *  @return 超时时间
 */
- (HLAPI* (^)(NSTimeInterval apiRequestTimeoutInterval))setTimeout;

/**
 *  用户api请求中的参数列表
 *  每次设置都会覆盖
 *  @return 一般来说是NSDictionary
 */
- (HLAPI* (^)(NSDictionary<NSString *, NSObject *> *parameters))setParams;

/**
 *  用户api请求中的参数列表
 *  每次设置都是添加新参数
 *  @return 一般来说是NSDictionary
 */
- (HLAPI* (^)(NSDictionary<NSString *, NSObject *> *parameters))addParams;

/**
 *  HTTP 请求的头部区域自定义
 *  @default
 *   默认为：@{
 *               @"Content-Type" : @"application/json; charset=utf-8"
 *           }
 *
 *  @return NSDictionary
 */
- (HLAPI* (^)(NSDictionary<NSString *, NSString *> *header))setHeader;

/**
 *  HTTP 请求的返回可接受的内容类型
 *  @default
 *   默认为：[NSSet setWithObjects:
 *            @"text/json",
 *            @"text/html",
 *            @"application/json",
 *            @"text/javascript", nil];
 *
 *  @return NSSet
 */
- (HLAPI* (^)(NSSet *contentTypes))setAccpetContentTypes;

/**
 *  自定义的RequestUrl 请求
 *  @descriptions:
 *    APIManager 对于RequestUrl 处理为：
 *     当customeUrl 不为空时，将直接返回customRequestUrl 作为请求数据
 *
 *  @return url String
 */
- (HLAPI* (^)(NSString *customURL))setCustomURL;

#pragma mark - handler block function
/**
 API完成后的成功回调
 写法：
 .success(^(id obj) {
 
 })

 @return HLAPI
 */
- (HLAPI *(^)(ReObjBlock))success;

/**
 API完成后的失败回调
 写法：

 @return HLAPI
 */
- (HLAPI *(^)(ReErrorBlock))failure;

/**
 API上传、下载等长时间执行的Progress进度
 写法：
 .progress(^(NSProgress *proc){
 NSLog(@"当前进度：%@", proc);
 })

 @return HLAPI
 */
- (HLAPI *(^)(ProgressBlock))progress;

/**
 *  用于组织POST体FormData
 */
/**
 *  @method      formData
 */
- (HLAPI *(^)(RequestConstructingBodyBlock))formData;

#pragma mark - functory method
+ (nullable instancetype)API;


#pragma mark - Process

/**
 *  开启API 请求
 */
- (HLAPI *)start;

/**
 *  取消API 请求
 */
- (HLAPI *)cancel;

@end
NS_ASSUME_NONNULL_END
