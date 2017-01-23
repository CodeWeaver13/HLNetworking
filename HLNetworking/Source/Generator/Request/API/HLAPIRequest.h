//
//  HLAPIRequest.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLURLRequest.h"

@class HLAPIRequest;
NS_ASSUME_NONNULL_BEGIN

#pragma mark - 用于转换回调结果的代理
@protocol HLReformerDelegate <NSObject>
@required
/**
 一般用来进行JSON -> Model 数据的转换工作。返回的id，如果没有error，则为转换成功后的Model数据。如果有error， 则直接返回传参中的responseObject
 
 @param request 调用的request
 @param responseObject 请求的返回
 @param error 请求的错误
 @return 整理过后的请求数据
 */
- (nullable id)reformerObject:(id)responseObject andError:(NSError * _Nullable)error atRequest:(HLAPIRequest *)request;
@end

@interface HLAPIRequest : HLURLRequest
#pragma mark - property
@property (nonatomic, assign, readonly) BOOL useDefaultParams;
@property (nonatomic, strong, readonly) Class objClz;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSObject *> *parameters;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *header;
@property (nonatomic, copy, readonly) NSSet *accpetContentTypes;

#pragma mark - parameters append method
/**
 进行JSON -> Model 数据的转换工作的Delegate
 如果设置了ReformerDelegate，则使用ReformerDelegate的obj解析，否则直接返回
 提供该Delegate主要用于Reformer的不相关代码的解耦工作
 
 param responseObject 请求回调对象
 param error          错误信息
 
 @return 请求结果数据
 */
- (HLAPIRequest *(^)(id<HLReformerDelegate> delegate))setObjReformerDelegate;
/**
 HTTP 请求的返回可接受的内容类型
 默认为：[NSSet setWithObjects:
 @"text/json",
 @"text/html",
 @"application/json",
 @"text/javascript", nil];
 */
- (HLAPIRequest *(^)(NSSet *contentTypes))setAccpetContentTypes;
// 是否使用APIManager.config的默认参数
- (HLAPIRequest *(^)(BOOL enable))enableDefaultParams;
// 设置HLAPI对应的返回值模型类型
- (HLAPIRequest *(^)(NSString *clzName))setResponseClass;
// 请求方法 GET POST等
- (HLAPIRequest *(^)(HLRequestMethodType requestMethodType))setMethod;
// Request 序列化类型：JSON, HTTP, 见HLRequestSerializerType
- (HLAPIRequest *(^)(HLRequestSerializerType requestSerializerType))setRequestType;
// Response 序列化类型： JSON, HTTP
- (HLAPIRequest *(^)(HLResponseSerializerType responseSerializerType))setResponseType;
// 请求中的参数，每次设置都会覆盖之前的内容
- (HLAPIRequest *(^)(NSDictionary<NSString *, id> *parameters))setParams;
// 请求中的参数，每次设置都是添加新参数，不会覆盖之前的内容
- (HLAPIRequest *(^)(NSDictionary<NSString *, id> *parameters))addParams;
// HTTP 请求的头部区域自定义，默认为nil
- (HLAPIRequest *(^)(NSDictionary<NSString *, NSString *> *header))setHeader;

#pragma mark - process
// 开启API 请求
- (HLAPIRequest *)start;
// 取消API 请求
- (HLAPIRequest *)cancel;

#pragma mark - handler block function
/**
 用于组织POST体的formData
 */
- (HLAPIRequest *(^)(HLRequestConstructingBodyBlock))formData;

#pragma mark - 重写父类方法，用于转换类型
// 设置HLAPI的requestDelegate
- (HLAPIRequest *(^)(id<HLURLRequestDelegate> delegate))setDelegate;
// 设置API的baseURL，该参数会覆盖config中的baseURL
- (HLAPIRequest *(^)(NSString *baseURL))setBaseURL;
// urlQuery，baseURL后的地址
- (HLAPIRequest *(^)(NSString *path))setPath;
// 自定义的RequestUrl，该参数会无视任何baseURL的设置，优先级最高
- (HLAPIRequest *(^)(NSString *customURL))setCustomURL;
// HTTPS 请求的Security策略
- (HLAPIRequest *(^)(HLSecurityPolicyConfig *securityPolicy))setSecurityPolicy;
// HTTP 请求的Cache策略
- (HLAPIRequest *(^)(NSURLRequestCachePolicy requestCachePolicy))setCachePolicy;
// HTTP 请求超时的时间，默认为15秒
- (HLAPIRequest *(^)(NSTimeInterval requestTimeoutInterval))setTimeout;
/**
 API完成后的成功回调
 写法：
 .success(^(id obj) {
 dosomething
 })
 */
- (HLAPIRequest *(^)(HLSuccessBlock))success;
/**
 API完成后的失败回调
 写法：
 .failure(^(NSError *error) {
 
 })
 */
- (HLAPIRequest *(^)(HLFailureBlock))failure;
/**
 API上传、下载等长时间执行的Progress进度
 写法：
 .progress(^(NSProgress *proc){
 NSLog(@"当前进度：%@", proc);
 })
 */
- (HLAPIRequest *(^)(HLProgressBlock))progress;
/**
 用于Debug的Block
 block内返回HLDebugMessage对象
 */
- (HLAPIRequest *(^)(HLDebugBlock))debug;
@end
NS_ASSUME_NONNULL_END
