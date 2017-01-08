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
NS_ASSUME_NONNULL_BEGIN

#pragma mark - HLAPIRequestDelegate
@protocol HLAPIRequestDelegate <NSObject>

@optional
// 请求将要发出
- (void)requestWillBeSentWithAPI:(HLAPI *)api;
// 请求已经发出
- (void)requestDidSentWithAPI:(HLAPI *)api;
@end

#pragma mark - HLObjReformerProtocol
@protocol HLObjReformerProtocol <NSObject>
@required
/**
 一般用来进行JSON -> Model 数据的转换工作。返回的id，如果没有error，则为转换成功后的Model数据。如果有error， 则直接返回传参中的responseObject

 @param api 调用的api
 @param responseObject 请求的返回
 @param error 请求的错误
 @return 整理过后的请求数据
 */
- (nullable id)objReformerWithAPI:(HLAPI *)api andResponseObject:(id)responseObject andError:(NSError * _Nullable)error;
@end

#pragma mark - HLAPI
@interface HLAPI : NSObject<NSCopying>
@property (nonatomic, assign, readonly) BOOL useDefaultParams;
@property (nonatomic, strong, readonly) Class objClz;
@property (nonatomic, copy, readonly) NSString *baseURL;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, assign, readonly) NSTimeInterval timeoutInterval;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSObject *> *parameters;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *header;
@property (nonatomic, copy, readonly) NSSet *accpetContentTypes;
@property (nonatomic, copy, nullable, readonly) NSString *cURL;

// 请使用API
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// 是否使用APIManager.config的默认参数
- (HLAPI *(^)(BOOL enable))enableDefaultParams;

// 设置HLAPI对应的返回值模型类型
- (HLAPI *(^)(NSString *clzName))setResponseClass;

/** 
 设置HLAPI的requestDelegate，对应代理方法为：
 请求将要发出 - (void)requestWillBeSentWithAPI:(HLAPI *)api;
 请求已经发出 - (void)requestDidSentWithAPI:(HLAPI *)api;
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

// 设置API的baseURL，该参数会覆盖config中的baseURL
- (HLAPI *(^)(NSString *baseURL))setBaseURL;

// urlQuery，baseURL后的地址
- (HLAPI *(^)(NSString *path))setPath;

// HTTPS 请求的Security策略
- (HLAPI* (^)(HLSecurityPolicyConfig *apiSecurityPolicy))setSecurityPolicy;

// 请求方法 GET POST等
- (HLAPI* (^)(HLRequestMethodType requestMethodType))setMethod;

// Request 序列化类型：JSON, HTTP, 见HLRequestSerializerType
- (HLAPI* (^)(HLRequestSerializerType requestSerializerType))setRequestType;

// Response 序列化类型： JSON, HTTP
- (HLAPI* (^)(HLResponseSerializerType responseSerializerType))setResponseType;

// HTTP 请求的Cache策略
- (HLAPI* (^)(NSURLRequestCachePolicy apiRequestCachePolicy))setCachePolicy;

// HTTP 请求超时的时间，默认为15秒
- (HLAPI* (^)(NSTimeInterval apiRequestTimeoutInterval))setTimeout;

// 请求中的参数，每次设置都会覆盖之前的内容
- (HLAPI* (^)(NSDictionary<NSString *, id> *parameters))setParams;

// 请求中的参数，每次设置都是添加新参数，不会覆盖之前的内容
- (HLAPI* (^)(NSDictionary<NSString *, id> *parameters))addParams;

// HTTP 请求的头部区域自定义，默认为nil
- (HLAPI* (^)(NSDictionary<NSString *, NSString *> *header))setHeader;

/** 
 HTTP 请求的返回可接受的内容类型
 默认为：[NSSet setWithObjects:
 @"text/json",
 @"text/html",
 @"application/json",
 @"text/javascript", nil];
 */
- (HLAPI* (^)(NSSet *contentTypes))setAccpetContentTypes;

// 自定义的RequestUrl，该参数会无视任何baseURL的设置，优先级最高
- (HLAPI* (^)(NSString *customURL))setCustomURL;

#pragma mark - handler block function
/**
 API完成后的成功回调
 写法：
 .success(^(id obj) {
    dosomething
 })
 */
- (HLAPI *(^)(HLSuccessBlock))success;

/**
 API完成后的失败回调
 写法：
 .failure(^(NSError *error) {
 
 })
 */
- (HLAPI *(^)(HLFailureBlock))failure;

/**
 API上传、下载等长时间执行的Progress进度
 写法：
 .progress(^(NSProgress *proc){
    NSLog(@"当前进度：%@", proc);
 })
 */
- (HLAPI *(^)(HLProgressBlock))progress;

/**
 用于组织POST体的formData
 */
- (HLAPI *(^)(HLRequestConstructingBodyBlock))formData;

/**
 用于Debug的Block 
 block内返回HLDebugMessage对象
 */
- (HLAPI *(^)(HLDebugBlock))debug;

#pragma mark - functory method
+ (instancetype)API;

- (NSDictionary *)toDictionary;

- (NSString *)hashKey;

#pragma mark - Process
// 开启API 请求
- (HLAPI *)start;

// 取消API 请求
- (HLAPI *)cancel;

@end
NS_ASSUME_NONNULL_END
