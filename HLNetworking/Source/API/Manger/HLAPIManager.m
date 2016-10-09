//
//  HLAPIManager.m
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/17.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "AFNetworking.h"
#import "HLAPIManager.h"
#import "HLHttpHeaderDelegate.h"
#import "HLSecurityPolicyConfig.h"
#import "HLAPIResponseDelegate.h"
#import "HLMultipartFormDataProtocol.h"
#import "HLNetworkErrorProtocol.h"
#import "HLNetworkConfig.h"
#import "HLAPI.h"
#import "HLAPI_InternalParams.h"
#import "HLAPIBatchRequests.h"
#import "HLAPISyncBatchRequests.h"

void HLJudgeVersionSwitch(BOOL isR) {
    [[NSUserDefaults standardUserDefaults] setBool:isR forKey:@"isR"];
}

// 创建任务队列
static dispatch_queue_t qkhl_api_http_creation_queue() {
    static dispatch_queue_t qkhl_api_http_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        qkhl_api_http_creation_queue =
        dispatch_queue_create("com.qkhl.pp.networking.wangshiyu13.api.creation", DISPATCH_QUEUE_SERIAL);
    });
    return qkhl_api_http_creation_queue;
}

static HLAPIManager *shared = nil;

@interface HLAPIManager ()

@property (nonatomic, strong) NSCache *sessionManagerCache;
@property (nonatomic, strong) NSCache *sessionTasksCache;
@property (nonatomic, strong) NSMutableSet<id <HLNetworkErrorProtocol>> *errorObservers;

@end

@implementation HLAPIManager

#pragma mark - init method
+ (HLAPIManager *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (!shared) {
        shared = [super init];
        shared.config = [[HLNetworkConfig alloc]init];
        shared.errorObservers = [[NSMutableSet alloc]init];
    }
    return shared;
}

#pragma mark - serializer

/**
 从API中获取request序列化类型
 
 @param api 调用的API
 
 @return 序列化类型
 */
- (AFHTTPRequestSerializer *)requestSerializerForAPI:(HLAPI *)api {
    NSParameterAssert(api);
    
    AFHTTPRequestSerializer *requestSerializer;
    if (api.requestSerializerType == RequestJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    } else {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    
    requestSerializer.cachePolicy          = api.cachePolicy;
    requestSerializer.timeoutInterval      = api.timeoutInterval;
    NSDictionary *requestHeaderFieldParams = api.header;
    if (![[requestHeaderFieldParams allKeys] containsObject:@"User-Agent"] &&
        self.config.userAgent) {
        [requestSerializer setValue:self.config.userAgent forHTTPHeaderField:@"User-Agent"];
    }
    if (requestHeaderFieldParams) {
        [requestHeaderFieldParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
    return requestSerializer;
}

/**
 从API中获取reponse序列化类型

 @param api 调用的API

 @return 序列化类型
 */
- (AFHTTPResponseSerializer *)responseSerializerForAPI:(HLAPI *)api {
    NSParameterAssert(api);
    AFHTTPResponseSerializer *responseSerializer;
    if (api.responseSerializerType == ResponseJSON) {
        responseSerializer = [AFJSONResponseSerializer serializer];
    } else {
        responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    responseSerializer.acceptableContentTypes = api.contentTypes;
    return responseSerializer;
}

#pragma mark - Request Invoke Organize

/**
 从API中获取requestBaseURL
 
 @param api 调用的API
 
 @return baseURL
 */
- (NSString *)requestBaseUrlStringWithAPI:(HLAPI *)api {
    NSParameterAssert(api);
    
    // 如果定义了自定义的cURL, 则直接使用
    if (api.cURL) {
        NSURL *url  = [NSURL URLWithString:api.cURL];
        NSURL *root = [NSURL URLWithString:@"/" relativeToURL:url];
        return [NSString stringWithFormat:@"%@", root.absoluteString];
    }
    
    NSAssert(api.baseURL != nil || self.config.baseURL != nil,
             @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
    
    NSString *baseURL = api.baseURL ? : self.config.baseURL;
    
    // 在某些情况下，一些用户会直接把整个url地址写进 baseUrl
    // 因此，还需要对baseUrl 进行一次切割
    NSURL *theUrl = [NSURL URLWithString:baseURL];
    NSURL *root   = [NSURL URLWithString:@"/" relativeToURL:theUrl];
    return [NSString stringWithFormat:@"%@", root.absoluteString];
}

/**
 从API中获取requestURL

 @param api 调用的API

 @return requestURL
 */
- (NSString *)requestUrlStringWithAPI:(HLAPI *)api {
    NSParameterAssert(api);
    
    NSString *baseUrlStr = [self requestBaseUrlStringWithAPI:api];
    // 如果定义了自定义的cURL, 则直接使用
    if (api.cURL && ![api.cURL isEqualToString:@""]) {
        return [NSURL URLWithString:api.cURL].absoluteString;
    }
    NSAssert(api.baseURL != nil || self.config.baseURL != nil,
             @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
    
    // 如果啥都没定义，则使用BaseUrl + apiversion(可选) + path 组成 UrlString
    NSString *requestURLString;
    if (self.config.apiVersion && ![self.config.apiVersion isEqualToString:@""]) {
        requestURLString = [NSString stringWithFormat:@"%@/%@/%@", baseUrlStr, self.config.apiVersion, api.path ? : @""];
    } else {
        requestURLString = [NSString stringWithFormat:@"%@/%@", baseUrlStr, api.path ? : @""];
    }
    return [NSURL URLWithString:requestURLString].absoluteString;
}

// Request Protocol

/**
 根据API获取请求参数

 @param api 调用的API

 @return 请求参数字典
 */
- (NSDictionary<NSString *, NSObject *> *)requestParamsWithAPI:(HLAPI *)api {
    NSParameterAssert(api);
    return api.parameters;
}

#pragma mark - AFSessionManager
/**
 根据API的BaseURL创建AFSessionManager

 @param api 调用的API

 @return AFHTTPSessionManager
 */
- (AFHTTPSessionManager *)sessionManagerWithAPI:(HLAPI *)api {
    NSParameterAssert(api);
    // Request 序列化工具
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForAPI:api];
    if (!requestSerializer) {
        return nil;
    }
    
    // Response 序列化工具
    AFHTTPResponseSerializer *responseSerializer = [self responseSerializerForAPI:api];
    if (!responseSerializer) {
        return nil;
    }
    
    NSString *baseUrlStr = [self requestBaseUrlStringWithAPI:api];
    // AFHTTPSession
    AFHTTPSessionManager *sessionManager;
    sessionManager = [self.sessionManagerCache objectForKey:baseUrlStr];
    if (!sessionManager) {
        sessionManager = [self newSessionManagerWithBaseUrlStr:baseUrlStr];
        [self.sessionManagerCache setObject:sessionManager forKey:baseUrlStr];
    }
    
    sessionManager.requestSerializer = requestSerializer;
    sessionManager.responseSerializer = responseSerializer;
    sessionManager.securityPolicy = [self securityPolicyWithAPI:api];
    
    return sessionManager;
}

/**
 根据传入的BaseURL创建新的SessionManager

 @param baseUrlStr 传入的BaseURL

 @return AFHTTPSessionManager
 */
- (AFHTTPSessionManager *)newSessionManagerWithBaseUrlStr:(NSString *)baseUrlStr {
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    if (self.config) {
        sessionConfig.HTTPMaximumConnectionsPerHost = self.config.maxHttpConnectionPerHost;
    } else {
        sessionConfig.HTTPMaximumConnectionsPerHost = MAX_HTTP_CONNECTION_PER_HOST;
    }
    return [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrlStr]
                                    sessionConfiguration:sessionConfig];
}

/**
 从API中获取securityPolicy（安全策略）
 
 @param api 调用的API
 
 @return securityPolicy
 */
- (AFSecurityPolicy *)securityPolicyWithAPI:(HLAPI *)api {
    NSUInteger pinningMode                  = api.securityPolicy.SSLPinningMode;
    AFSecurityPolicy *securityPolicy        = [AFSecurityPolicy policyWithPinningMode:pinningMode];
    securityPolicy.allowInvalidCertificates = api.securityPolicy.allowInvalidCertificates;
    securityPolicy.validatesDomainName      = api.securityPolicy.validatesDomainName;
    return securityPolicy;
}

#pragma mark - Response Handler

/**
 API成功的方法

 @param responseObject 返回的对象
 @param api            调用的API
 */
- (void)handleSuccWithResponse:(id)responseObject andAPI:(HLAPI *)api completion:(void (^)())completion {
    [self callAPICompletion:api obj:responseObject error:nil completion:completion];
}

/**
 API失败的方法

 @param error 返回的错误
 @param api   调用的API
 */
- (void)handleFailureWithError:(NSError *)error andAPI:(HLAPI *)api completion:(void (^)())completion  {
    if (error) {
        [self.errorObservers enumerateObjectsUsingBlock:^(id<HLNetworkErrorProtocol> observer, BOOL * _Nonnull stop) {
            [observer networkErrorInfo:error];
        }];
    }
    
    // Error -999, representing API Cancelled
    if ([error.domain isEqualToString: NSURLErrorDomain] &&
        error.code == NSURLErrorCancelled) {
        [self callAPICompletion:api obj:nil error:error completion:completion];
        return;
    }
    
    // 默认 "服务器连接错误，请稍候重试"
    NSString *errorTypeStr = self.config.generalErrorTypeStr;
    NSMutableDictionary *tmpUserInfo = [[NSMutableDictionary alloc]initWithDictionary:error.userInfo copyItems:NO];
    if (![[tmpUserInfo allKeys] containsObject:NSLocalizedFailureReasonErrorKey]) {
        [tmpUserInfo setValue: NSLocalizedString(errorTypeStr, nil) forKey:NSLocalizedFailureReasonErrorKey];
    }
    if (![[tmpUserInfo allKeys] containsObject:NSLocalizedRecoverySuggestionErrorKey]) {
        [tmpUserInfo setValue: NSLocalizedString(errorTypeStr, nil)  forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    // 加上 networking error code
    NSString *newErrorDescription = errorTypeStr;
    if (self.config.isErrorCodeDisplayEnabled) {
        newErrorDescription = [NSString stringWithFormat:@"%@ (%ld)", errorTypeStr, (long)error.code];
    }
    [tmpUserInfo setValue:NSLocalizedString(newErrorDescription, nil) forKey:NSLocalizedDescriptionKey];
    
    NSDictionary *userInfo = [tmpUserInfo copy];
    NSError *err = [NSError errorWithDomain:error.domain
                                       code:error.code
                                   userInfo:userInfo];
    
    [self callAPICompletion:api obj:nil error:err completion:completion];
}

/**
 API完成的回调方法

 @param api   调用的API
 @param obj   返回的对象
 @param error 返回的错误
 */
- (void)callAPICompletion:(HLAPI *)api obj:(id)obj error:(NSError *)error completion:(void (^)())completion {
    if (api.objReformerDelegate) {
        obj = [api.objReformerDelegate apiResponseObjReformerWithAPI:api
                                                     andResponseObject:obj
                                                              andError:error];
    }
    if (self.responseDelegate) {
        if ([self.responseDelegate.requestAPIs containsObject:api]) {
            if (error) {
                if ([api apiFailureHandler]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        api.apiFailureHandler(error);
                    });
                }
                if ([self.responseDelegate respondsToSelector:@selector(requestFailureWithResponseError:atAPI:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.responseDelegate requestFailureWithResponseError:error atAPI:api];
                    });
                }
            } else {
                if ([api apiSuccessHandler]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        api.apiSuccessHandler(obj);
                    });
                }
                if ([self.responseDelegate respondsToSelector:@selector(requestSucessWithResponseObject:atAPI:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.responseDelegate requestSucessWithResponseObject:obj atAPI:api];
                    });
                }
            }
        }
    }
    completion();
}

#pragma mark - Send Sync Batch Requests

/**
 使用信号量做同步请求

 @param apis api集合
 */
- (void)sendSyncBatchAPIRequests:(nonnull HLAPISyncBatchRequests *)apis {
    NSParameterAssert(apis);
    
    NSAssert([[apis.apiRequestsArray valueForKeyPath:@"hash"] count] == [apis.apiRequestsArray count],
             @"不能在集合中加入相同的 API");
    NSString *queueName = [NSString stringWithFormat:@"com.qkhl.pp.networking.wangshiyu13.%lu", (unsigned long)apis.hash];
    __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_group_t batch_api_group = dispatch_group_create();
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL), ^{
        [apis.apiRequestsArray enumerateObjectsUsingBlock:^(id  _Nonnull api, NSUInteger idx, BOOL * _Nonnull stop) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_group_enter(batch_api_group);
            __strong typeof (weakSelf) strongSelf = weakSelf;
            AFHTTPSessionManager *sessionManager = [strongSelf sessionManagerWithAPI:api];
            if (!sessionManager) {
                *stop = YES;
                dispatch_group_leave(batch_api_group);
            }
            sessionManager.completionGroup = batch_api_group;
            
            [strongSelf _sendSingleAPIRequest:api
                           withSessionManager:sessionManager
                           andCompletionGroup:batch_api_group
                              completionBlock:^{
                                  dispatch_semaphore_signal(semaphore);
                              }];
        }];
        dispatch_group_notify(batch_api_group, dispatch_get_main_queue(), ^{
            if (apis.delegate) {
                [apis.delegate batchRequestsAllDidFinished:apis];
            }
        });
    });
}

#pragma mark - Send Batch Requests
- (void)sendBatchAPIRequests:(nonnull HLAPIBatchRequests *)apis {
    NSParameterAssert(apis);
    
    NSAssert([[apis.apiRequestsSet valueForKeyPath:@"hash"] count] == [apis.apiRequestsSet count],
             @"不能在集合中加入相同的 API");
    
    dispatch_group_t batch_api_group = dispatch_group_create();
    __weak typeof(self) weakSelf = self;
    [apis.apiRequestsSet enumerateObjectsUsingBlock:^(id api, BOOL * stop) {
        dispatch_group_enter(batch_api_group);
        
        __strong typeof (weakSelf) strongSelf = weakSelf;
        AFHTTPSessionManager *sessionManager = [strongSelf sessionManagerWithAPI:api];
        if (!sessionManager) {
            *stop = YES;
            dispatch_group_leave(batch_api_group);
        }
        sessionManager.completionGroup = batch_api_group;
        
        [strongSelf _sendSingleAPIRequest:api
                       withSessionManager:sessionManager
                       andCompletionGroup:batch_api_group
                          completionBlock:nil];
    }];
    dispatch_group_notify(batch_api_group, dispatch_get_main_queue(), ^{
        if (apis.delegate) {
            [apis.delegate batchAPIRequestsDidFinished:apis];
        }
    });
}

#pragma mark - Send Request

/**
 发送单个API

 @param api 需要发送的API
 */
- (void)sendAPIRequest:(nonnull HLAPI *)api {
    NSParameterAssert(api);
    NSAssert(self.config, @"Config不能为空");
    
    dispatch_async(qkhl_api_http_creation_queue(), ^{
        AFHTTPSessionManager *sessionManager = [self sessionManagerWithAPI:api];
        if (!sessionManager) {
            return;
        }
        [self _sendSingleAPIRequest:api withSessionManager:sessionManager andCompletionGroup:nil completionBlock:^{
            
        }];
    });
}

- (void)_sendSingleAPIRequest:(HLAPI *)api
           withSessionManager:(AFHTTPSessionManager *)sessionManager
           andCompletionGroup:(dispatch_group_t)completionGroup
              completionBlock:(void (^)())completion {
    NSParameterAssert(api);
    NSParameterAssert(sessionManager);
    
    __weak typeof(self) weakSelf = self;
    NSString *requestUrlStr = [self requestUrlStringWithAPI:api];
    NSDictionary<NSString *,NSObject *> *requestParams = [self requestParamsWithAPI:api];
    NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)[api hash]];
    
    // 如果缓存中已有当前task，则立即使api返回失败回调，错误信息为frequentRequestErrorStr，如果是apiBatch，则整组移除
    if ([self.sessionTasksCache objectForKey:hashKey]) {
        NSString *errorStr     = self.config.frequentRequestErrorStr;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr
                                   };
        NSError *cancelError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorCancelled
                                               userInfo:userInfo];
        [self callAPICompletion:api obj:nil error:cancelError completion:completion];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
        completion();
        return;
    }
    
    // 设置reachbility,监听url为baseURL
    SCNetworkReachabilityRef hostReachable = SCNetworkReachabilityCreateWithName(NULL, [sessionManager.baseURL.host UTF8String]);
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(hostReachable, &flags);
    bool isReachable = success &&
    (flags & kSCNetworkFlagsReachable) &&
    !(flags & kSCNetworkFlagsConnectionRequired);
    if (hostReachable) {
        CFRelease(hostReachable);
    }
    
    // 如果无网络，则立即使api响应失败回调，错误信息是networkNotReachableErrorStr，如果是apiBatch，则整组移除
    if (!isReachable) {
        NSString *errorStr     = self.config.networkNotReachableErrorStr;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr,
                                   NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@ 无法访问", sessionManager.baseURL.host]
                                   };
        NSError *networkUnreachableError = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:NSURLErrorCannotConnectToHost
                                                           userInfo:userInfo];
        [self callAPICompletion:api obj:nil error:networkUnreachableError completion:completion];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
        return;
    }
    
    /**
     task成功Block
     */
    void (^successBlock)(NSURLSessionDataTask *task, id responseObject)
    = ^(NSURLSessionDataTask * task, id responseObject) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        if (strongSelf.config.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        [strongSelf handleSuccWithResponse:responseObject andAPI:api completion:completion];
        [strongSelf.sessionTasksCache removeObjectForKey:hashKey];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
    };
    
    /**
     task失败Block
     */
    void (^failureBlock)(NSURLSessionDataTask * task, NSError * error)
    = ^(NSURLSessionDataTask * task, NSError * error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        if (strongSelf.config.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        [strongSelf handleFailureWithError:error andAPI:api completion:completion];
        [strongSelf.sessionTasksCache removeObjectForKey:hashKey];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
    };
    
    /**
     进度Block
     */
    void (^progressBlock)(NSProgress *progress)
    = api.apiProgressHandler ? ^(NSProgress *progress) {
        if (progress.totalUnitCount <= 0) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            api.apiProgressHandler(progress);
            if ([self.responseDelegate respondsToSelector:@selector(requestProgress:atAPI:)]) {
                [self.responseDelegate requestProgress:progress atAPI:api];
            }
        });
    } : nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([api respondsToSelector:@selector(requestWillBeSent)]) {
        if ([[NSThread currentThread] isMainThread]) {
            [api performSelector:@selector(requestWillBeSent)];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [api performSelector:@selector(requestWillBeSent)];
            });
        }
    }
#pragma clang diagnostic pop
    
    if (self.config.isNetworkingActivityIndicatorEnabled) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    NSURLSessionDataTask *dataTask;
    
    switch (api.requestMethodType) {
        case GET: {
            dataTask =
            [sessionManager GET:requestUrlStr
                     parameters:requestParams
                       progress:progressBlock
                        success:successBlock
                        failure:failureBlock];
        }
            break;
        case DELETE: {
            dataTask =
            [sessionManager DELETE:requestUrlStr
                        parameters:requestParams
                           success:successBlock
                           failure:failureBlock];
        }
            break;
        case PATCH: {
            dataTask =
            [sessionManager PATCH:requestUrlStr
                       parameters:requestParams
                          success:successBlock
                          failure:failureBlock];
        }
            break;
        case PUT: {
            dataTask =
            [sessionManager PUT:requestUrlStr
                     parameters:requestParams
                        success:successBlock
                        failure:failureBlock];
        }
            break;
        case HEAD: {
            dataTask =
            [sessionManager HEAD:requestUrlStr
                      parameters:requestParams
                         success:^(NSURLSessionDataTask * _Nonnull task) {
                             if (successBlock) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     successBlock(task, nil);
                                 });
                             }
                         }
                         failure:failureBlock];
        }
            break;
        case POST:
        {
            if (![api apiRequestConstructingBodyBlock]) {
                dataTask =
                [sessionManager POST:requestUrlStr
                          parameters:requestParams
                            progress:progressBlock
                             success:successBlock
                             failure:failureBlock];
            } else {
                void (^formDataBlock)(id <AFMultipartFormData> formData)
                = ^(id <AFMultipartFormData> formData) {
                    api.apiRequestConstructingBodyBlock((id<HLMultipartFormDataProtocol>)formData);
                };
                dataTask = [sessionManager POST:requestUrlStr
                                     parameters:requestParams
                      constructingBodyWithBlock:formDataBlock
                                       progress:progressBlock
                                        success:successBlock
                                        failure:failureBlock];
            }
        }
            break;
        default:
            dataTask =
            [sessionManager GET:requestUrlStr
                     parameters:requestParams
                       progress:progressBlock
                        success:successBlock
                        failure:failureBlock];
            break;
    }
    if (dataTask) {
        [self.sessionTasksCache setObject:dataTask forKey:hashKey];
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([api respondsToSelector:@selector(requestDidSent)]) {
        if ([[NSThread currentThread] isMainThread]) {
            [api performSelector:@selector(requestDidSent)];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [api performSelector:@selector(requestDidSent)];
            });
        }
    }
#pragma clang diagnostic pop
}

- (void)cancelAPIRequest:(nonnull HLAPI *)api {
    dispatch_async(qkhl_api_http_creation_queue(), ^{
        NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)[api hash]];
        NSURLSessionDataTask *dataTask = [self.sessionTasksCache objectForKey:hashKey];
        [self.sessionTasksCache removeObjectForKey:hashKey];
        if (dataTask) {
            api.apiSuccessHandler = nil;
            api.apiFailureHandler = nil;
            api.apiProgressHandler = nil;
            api.apiRequestConstructingBodyBlock = nil;
            [dataTask cancel];
        }
    });
}

#pragma mark - get task
- (NSURLSessionDataTask * _Nullable)getAPIWithAPIHash:(NSUInteger)name {
    NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)name];
    NSURLSessionDataTask *task = [self.sessionTasksCache objectForKey:hashKey];
    return task;
}

#pragma mark - Network Error Observer
- (void)registerNetworkErrorObserver:(nonnull id<HLNetworkErrorProtocol>)observer {
    [self.errorObservers addObject:observer];
}


- (void)removeNetworkErrorObserver:(nonnull id<HLNetworkErrorProtocol>)observer {
    if ([self.errorObservers containsObject:observer]) {
        [self.errorObservers removeObject:observer];
    }
}

#pragma mark - lazy load getter
- (NSCache *)sessionManagerCache {
    if (!_sessionManagerCache) {
        _sessionManagerCache = [[NSCache alloc] init];
    }
    return _sessionManagerCache;
}

- (NSCache *)sessionTasksCache {
    if (!_sessionTasksCache) {
        _sessionTasksCache = [[NSCache alloc] init];
    }
    return _sessionTasksCache;
}
@end
