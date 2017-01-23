//
//  HLTaskRequest.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLURLRequest.h"
NS_ASSUME_NONNULL_BEGIN
@interface HLTaskRequest : HLURLRequest

#pragma mark - property
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, copy, readonly) NSString *resumePath;

#pragma mark - parameters append method
// 设置下载或者上传的本地文件路径
- (HLTaskRequest *(^)(NSString *filePath))setFilePath;
// 设置task的类型（上传/下载）
- (HLTaskRequest *(^)(HLRequestTaskType requestTaskType))setTaskType;

#pragma mark - process
// 开启API 请求
- (HLTaskRequest *)start;
// 取消API 请求
- (HLTaskRequest *)cancel;
// 继续Task
- (HLTaskRequest *)resume;
// 暂停Task
- (HLTaskRequest *)pause;

#pragma mark - 重写父类方法，用于转换类型
// 设置HLAPI的requestDelegate
- (HLTaskRequest *(^)(id<HLURLRequestDelegate> delegate))setDelegate;
// 设置API的baseURL，该参数会覆盖config中的baseURL
- (HLTaskRequest *(^)(NSString *baseURL))setBaseURL;
// urlQuery，baseURL后的地址
- (HLTaskRequest *(^)(NSString *path))setPath;
// 自定义的RequestUrl，该参数会无视任何baseURL的设置，优先级最高
- (HLTaskRequest *(^)(NSString *customURL))setCustomURL;
// HTTPS 请求的Security策略
- (HLTaskRequest *(^)(HLSecurityPolicyConfig *securityPolicy))setSecurityPolicy;
// HTTP 请求的Cache策略
- (HLTaskRequest *(^)(NSURLRequestCachePolicy requestCachePolicy))setCachePolicy;
// HTTP 请求超时的时间，默认为15秒
- (HLTaskRequest *(^)(NSTimeInterval requestTimeoutInterval))setTimeout;
/**
 API完成后的成功回调
 写法：
 .success(^(id obj) {
 dosomething
 })
 */
- (HLTaskRequest *(^)(HLSuccessBlock))success;

/**
 API完成后的失败回调
 写法：
 .failure(^(NSError *error) {
 
 })
 */
- (HLTaskRequest *(^)(HLFailureBlock))failure;

/**
 API上传、下载等长时间执行的Progress进度
 写法：
 .progress(^(NSProgress *proc){
 NSLog(@"当前进度：%@", proc);
 })
 */
- (HLTaskRequest *(^)(HLProgressBlock))progress;
/**
 用于Debug的Block
 block内返回HLDebugMessage对象
 */
- (HLTaskRequest *(^)(HLDebugBlock))debug;
@end
NS_ASSUME_NONNULL_END
