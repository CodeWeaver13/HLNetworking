
//  HLAPIManager.m
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/17.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "HLAPIManager.h"
#import "HLNetworkMacro.h"
#import "HLHttpHeaderDelegate.h"
#import "HLSecurityPolicyConfig.h"
#import "HLAPIResponseDelegate.h"
#import "HLMultipartFormDataProtocol.h"
#import "HLNetworkErrorProtocol.h"
#import "HLNetworkConfig.h"
#import "HLAPI.h"
#import "HLAPI_InternalParams.h"
#import "HLAPIBatchRequests.h"
#import "HLAPIChainRequests.h"

BOOL HLJudgeVersion(void) {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"isR"];
}

void HLJudgeVersionSwitch(BOOL isR) {
    [[NSUserDefaults standardUserDefaults] setBool:isR forKey:@"isR"];
}

// 创建任务队列
static dispatch_queue_t qkhl_api_http_creation_queue() {
    static dispatch_queue_t qkhl_api_http_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        qkhl_api_http_creation_queue =
        dispatch_queue_create("com.qkhl.networking.wangshiyu13.api.callback.queue", DISPATCH_QUEUE_SERIAL);
    });
    return qkhl_api_http_creation_queue;
}

@interface HLAPIManager ()

@property (nonatomic, strong, readwrite) HLNetworkConfig *config;
@property (nonatomic, strong) NSMutableDictionary *sessionManagerCache;
@property (nonatomic, strong) NSMutableDictionary *sessionTasksCache;
@property (nonatomic, strong) NSHashTable<id <HLAPIResponseDelegate>> *responseObservers;
@property (nonatomic, strong) NSHashTable<id <HLNetworkErrorProtocol>> *errorObservers;

@property (nonatomic, strong) NSMutableDictionary <NSString *, AFNetworkReachabilityManager *> *reachabilities;
@property (nonatomic, assign, readwrite) HLReachabilityStatus reachabilityStatus;
@property (nonatomic, assign, readwrite, getter = isReachable) BOOL reachable;
@property (nonatomic, assign, readwrite, getter = isReachableViaWWAN) BOOL reachableViaWWAN;
@property (nonatomic, assign, readwrite, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

@end

@implementation HLAPIManager

#pragma mark - init method
+ (HLAPIManager *)manager {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [HLNetworkConfig config];
        _reachabilityStatus = HLReachabilityStatusUnknown;
        _reachabilities = [NSMutableDictionary dictionary];
        _sessionManagerCache = [NSMutableDictionary dictionary];
        _sessionTasksCache = [NSMutableDictionary dictionary];
        _errorObservers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
        _responseObservers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    }
    return self;
}

#pragma mark - SetupConfig
- (void)setupConfig:(void (^)(HLNetworkConfig * _Nonnull config))configBlock {
    HL_SAFE_BLOCK(configBlock, self.config);
}

+ (void)setupConfig:(void (^)(HLNetworkConfig * _Nonnull config))configBlock {
    return [[self sharedManager] setupConfig:configBlock];
}

#pragma mark - 创建AFHTTPSessionManager
/**
 根据API的BaseURL创建AFSessionManager

 @param api 调用的API

 @return AFHTTPSessionManager
 */
- (AFHTTPSessionManager *)sessionManagerWithAPI:(HLAPI *)api {
    NSParameterAssert(api);
    // Request 序列化
    AFHTTPRequestSerializer *requestSerializer;
    switch (api.requestSerializerType) {
        case RequestHTTP:
            requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        case RequestJSON:
            requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        case RequestPlist:
            requestSerializer = [AFPropertyListRequestSerializer serializer];
            break;
        default:
            break;
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
    if (!requestSerializer) {
        return nil;
    }
    
    // Response 序列化
    AFHTTPResponseSerializer *responseSerializer;
    switch (api.responseSerializerType) {
        case ResponseHTTP:
            responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case ResponseJSON:
            responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case ResponsePlist:
            responseSerializer = [AFPropertyListResponseSerializer serializer];
            break;
        case ResponseXML:
            responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        default:
            break;
    }
    responseSerializer.acceptableContentTypes = api.accpetContentTypes;
    if (!responseSerializer) {
        return nil;
    }
    
    NSString *baseUrlStr;
    // 如果定义了自定义的cURL, 则直接使用
    NSURL *cURL = [NSURL URLWithString:api.cURL];
    if (cURL) {
        baseUrlStr = [NSString stringWithFormat:@"%@://%@", cURL.scheme, cURL.host];
    } else {
        NSAssert(api.baseURL != nil || self.config.baseURL != nil,
                 @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
        
        NSString *tmpStr = api.baseURL ? : self.config.baseURL;
        
        // 在某些情况下，一些用户会直接把整个url地址写进 baseUrl
        // 因此，还需要对baseUrl 进行一次切割
        NSURL *tmpURL = [NSURL URLWithString:tmpStr];
        baseUrlStr = [NSString stringWithFormat:@"%@://%@", tmpURL.scheme, tmpURL.host];;
    }
    
    // 设置AFSecurityPolicy参数
    NSUInteger pinningMode                  = api.securityPolicy.SSLPinningMode;
    AFSecurityPolicy *securityPolicy        = [AFSecurityPolicy policyWithPinningMode:pinningMode];
    securityPolicy.allowInvalidCertificates = api.securityPolicy.allowInvalidCertificates;
    securityPolicy.validatesDomainName      = api.securityPolicy.validatesDomainName;
    NSString *cerPath                       = api.securityPolicy.cerFilePath;
    NSData *certData                        = [NSData dataWithContentsOfFile:cerPath];
    securityPolicy.pinnedCertificates       = [NSSet setWithObject:certData];
    
    // AFHTTPSession
    AFHTTPSessionManager *sessionManager = [self.sessionManagerCache objectForKey:baseUrlStr];
    if (!sessionManager) {
        // 根据传入的BaseURL创建新的SessionManager
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.HTTPMaximumConnectionsPerHost = self.config.maxHttpConnectionPerHost;
        sessionConfig.requestCachePolicy = api.cachePolicy ?: self.config.cachePolicy;
        sessionConfig.timeoutIntervalForRequest = api.timeoutInterval ?: self.config.requestTimeoutInterval;
        sessionConfig.URLCache = self.config.URLCache;
        sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrlStr]
                                                  sessionConfiguration:sessionConfig];
        [self.sessionManagerCache setObject:sessionManager forKey:baseUrlStr];
    }
    sessionManager.requestSerializer = requestSerializer;
    sessionManager.responseSerializer = responseSerializer;
    sessionManager.securityPolicy = securityPolicy;
    
    return sessionManager;
}

#pragma mark - Response Complete Handler
/**
 API完成的回调方法

 @param api   调用的API
 @param obj   返回的对象
 @param error 返回的错误
 @param completion 完成回调
 */
- (void)callAPICompletion:(HLAPI *)api obj:(id)obj error:(NSError *)error completion:(void (^)())completion {
    if (api.objReformerDelegate) {
        obj = [api.objReformerDelegate objReformerWithAPI:api andResponseObject:obj andError:error];
    }
    // 处理回调的block
    NSError *netError = error;
    if (error) {
        // 如果不是reachability无法访问host或用户取消错误(NSURLErrorCancelled)，则对错误提示进行处理
        if (![error.domain isEqualToString: NSURLErrorDomain] &&
            error.code != NSURLErrorCancelled) {
            // 使用KVC修改error内部属性
            // 默认使用self.config.generalErrorTypeStr = "服务器连接错误，请稍候重试"
            NSMutableDictionary *tmpUserInfo = [[NSMutableDictionary alloc]initWithDictionary:error.userInfo copyItems:NO];
            if (![[tmpUserInfo allKeys] containsObject:NSLocalizedFailureReasonErrorKey]) {
                tmpUserInfo[NSLocalizedFailureReasonErrorKey] = NSLocalizedString(self.config.generalErrorTypeStr, nil);
            }
            if (![[tmpUserInfo allKeys] containsObject:NSLocalizedRecoverySuggestionErrorKey]) {
                tmpUserInfo[NSLocalizedRecoverySuggestionErrorKey] = NSLocalizedString(self.config.generalErrorTypeStr, nil);
            }
            // 加上 networking error code
            NSString *newErrorDescription = self.config.generalErrorTypeStr;
            if (self.config.isErrorCodeDisplayEnabled) {
                newErrorDescription = [NSString stringWithFormat:@"%@, error code = (%ld)", self.config.generalErrorTypeStr, (long)error.code];
            }
            tmpUserInfo[NSLocalizedDescriptionKey] = NSLocalizedString(newErrorDescription, nil);
            NSDictionary *userInfo = [tmpUserInfo copy];
            netError = [NSError errorWithDomain:error.domain
                                        code:error.code
                                    userInfo:userInfo];
        }
        for (id<HLNetworkErrorProtocol> observer in self.errorObservers) {
            [observer networkErrorInfo:netError];
        }
        if ([api apiFailureHandler]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                api.apiFailureHandler(netError);
                api.apiFailureHandler = nil;
            });
        }
    } else {
        if ([api apiSuccessHandler]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                api.apiSuccessHandler(obj);
                api.apiSuccessHandler = nil;
            });
        }
    }
    
    // 处理回调的delegate
    for (id<HLAPIResponseDelegate> obj in self.responseObservers) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([obj.requestAPIs containsObject:api]) {
                if (netError) {
                    if ([obj respondsToSelector:@selector(requestFailureWithResponseError:atAPI:)]) {
                        [obj requestFailureWithResponseError:netError atAPI:api];
                    }
                } else {
                    if ([obj respondsToSelector:@selector(requestSucessWithResponseObject:atAPI:)]) {
                        [obj requestSucessWithResponseObject:obj atAPI:api];
                    }
                }
            }
        });
    }
    if (completion) {
        completion();
    }
}

#pragma mark - Send Sync Chain Requests

/**
 使用信号量做同步请求

 @param apis api集合
 */
- (void)sendChainAPIRequests:(nonnull HLAPIChainRequests *)apis {
    NSParameterAssert(apis);
    NSString *queueName = [NSString stringWithFormat:@"com.qkhl.networking.wangshiyu13.%lu", (unsigned long)apis.hash];
    __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_group_t batch_api_group = dispatch_group_create();
    @weakify(self);
    dispatch_async(dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL), ^{
        [apis enumerateObjectsUsingBlock:^(id  _Nonnull api, NSUInteger idx, BOOL * _Nonnull stop) {
            @strongify(self);
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_group_enter(batch_api_group);
            AFHTTPSessionManager *sessionManager = [self sessionManagerWithAPI:api];
            if (!sessionManager) {
                *stop = YES;
                dispatch_group_leave(batch_api_group);
            }
            sessionManager.completionGroup = batch_api_group;
            
            [self sendSingleAPIRequest:api
                    withSessionManager:sessionManager
                    andCompletionGroup:batch_api_group
                       completionBlock:^{
                           dispatch_semaphore_signal(semaphore);
                       }];
        }];
        dispatch_group_notify(batch_api_group, dispatch_get_main_queue(), ^{
            if (apis.delegate) {
                [apis.delegate chainRequestsAllDidFinished:apis];
            }
        });
    });
}

#pragma mark - Send Batch Requests
- (void)sendBatchAPIRequests:(nonnull HLAPIBatchRequests *)apis {
    NSParameterAssert(apis);
    dispatch_group_t batch_api_group = dispatch_group_create();
    @weakify(self);
    [apis.apiRequestsSet enumerateObjectsUsingBlock:^(id api, BOOL * stop) {
        @strongify(self);
        dispatch_group_enter(batch_api_group);
        AFHTTPSessionManager *sessionManager = [self sessionManagerWithAPI:api];
        if (!sessionManager) {
            *stop = YES;
            dispatch_group_leave(batch_api_group);
        }
        sessionManager.completionGroup = batch_api_group;
        
        [self sendSingleAPIRequest:api
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
    dispatch_async(qkhl_api_http_creation_queue(), ^{
        AFHTTPSessionManager *sessionManager = [self sessionManagerWithAPI:api];
        if (!sessionManager) {
            return;
        }
        [self sendSingleAPIRequest:api
                withSessionManager:sessionManager
                andCompletionGroup:nil
                   completionBlock:nil];
    });
}

- (void)sendSingleAPIRequest:(HLAPI *)api
          withSessionManager:(AFHTTPSessionManager *)sessionManager
          andCompletionGroup:(dispatch_group_t)completionGroup
             completionBlock:(void (^)())completion {
    NSParameterAssert(api);
    NSParameterAssert(sessionManager);
    @weakify(self);
    
    NSString *requestURLString;
    // 如果定义了自定义的cURL, 则直接使用
    NSURL *cURL = [NSURL URLWithString:api.cURL];
    if (cURL) {
        requestURLString = cURL.absoluteString;
    } else {
        NSAssert(api.baseURL != nil || self.config.baseURL != nil,
                 @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
        NSString *tmpBaseURLStr = api.baseURL ?: self.config.baseURL;
        NSURL *tmpBaseURL = [NSURL URLWithString:tmpBaseURLStr];
        // 使用BaseUrl + apiversion(可选) + path 组成 UrlString
        // 如果有apiVersion，则在requestUrlStr中插入该参数
        if (self.config.apiVersion && ![self.config.apiVersion isEqualToString:@""]) {
            requestURLString = [NSString stringWithFormat:@"%@/%@", tmpBaseURL.absoluteString, self.config.apiVersion];
        } else {
            requestURLString = tmpBaseURL.absoluteString;
        }
        if (api.path || ![api.path isEqualToString:@""]) {
            requestURLString = [NSString stringWithFormat:@"%@/%@", requestURLString, api.path];
        }
    }
    NSAssert(requestURLString != nil || ![requestURLString isEqualToString:@""], @"请求的URL有误！");
    
    // 生成请求参数
    NSMutableDictionary<NSString *, id> *requestParams = [NSMutableDictionary dictionaryWithDictionary:api.parameters];
    if (self.config.defaultParams && api.useDefaultParams) {
        [requestParams addEntriesFromDictionary:self.config.defaultParams];
    }
    
    NSString *hashKey = [self hashStringWithAPI:api];
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
        if (completion) {
            completion();
        }
        return;
    }
    
    // 设置reachbility,监听url为baseURL
    SCNetworkReachabilityRef hostReachable = SCNetworkReachabilityCreateWithName(NULL, [sessionManager.baseURL.host UTF8String]);
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(hostReachable, &flags);
    BOOL isReachable = success &&
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
                                   NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"网络异常，%@ 无法访问", sessionManager.baseURL.host]
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
        @strongify(self);
        if (self.config.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
#if DEBUG
        if (api.apiDebugHandler) {
            NSDictionary *dict = [self createDebugDictionaryWithAPI:api andTask:task andError:nil];
            api.apiDebugHandler(dict);
        }
#endif
        [self callAPICompletion:api obj:responseObject error:nil completion:completion];
        [self.sessionTasksCache removeObjectForKey:hashKey];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
    };
    
    /**
     task失败Block
     */
    void (^failureBlock)(NSURLSessionDataTask * task, NSError * error)
    = ^(NSURLSessionDataTask * task, NSError * error) {
        @strongify(self);
        if (self.config.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
#if DEBUG
        if (api.apiDebugHandler) {
            NSDictionary *dict = [self createDebugDictionaryWithAPI:api andTask:task andError:error];
            api.apiDebugHandler(dict);
        }
#endif
        [self callAPICompletion:api obj:nil error:error completion:completion];
        [self.sessionTasksCache removeObjectForKey:hashKey];
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
            for (id<HLAPIResponseDelegate> obj in self.responseObservers) {
                if ([obj respondsToSelector:@selector(requestProgress:atAPI:)]) {
                    [obj requestProgress:progress atAPI:api];
                }
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
            [sessionManager GET:requestURLString
                     parameters:requestParams
                       progress:progressBlock
                        success:successBlock
                        failure:failureBlock];
        }
            break;
        case DELETE: {
            dataTask =
            [sessionManager DELETE:requestURLString
                        parameters:requestParams
                           success:successBlock
                           failure:failureBlock];
        }
            break;
        case PATCH: {
            dataTask =
            [sessionManager PATCH:requestURLString
                       parameters:requestParams
                          success:successBlock
                          failure:failureBlock];
        }
            break;
        case PUT: {
            dataTask =
            [sessionManager PUT:requestURLString
                     parameters:requestParams
                        success:successBlock
                        failure:failureBlock];
        }
            break;
        case HEAD: {
            dataTask =
            [sessionManager HEAD:requestURLString
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
                [sessionManager POST:requestURLString
                          parameters:requestParams
                            progress:progressBlock
                             success:successBlock
                             failure:failureBlock];
            } else {
                void (^formDataBlock)(id <AFMultipartFormData> formData)
                = ^(id <AFMultipartFormData> formData) {
                    api.apiRequestConstructingBodyBlock((id<HLMultipartFormDataProtocol>)formData);
                };
                dataTask = [sessionManager POST:requestURLString
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
            [sessionManager GET:requestURLString
                     parameters:requestParams
                       progress:progressBlock
                        success:successBlock
                        failure:failureBlock];
            break;
    }
    if (dataTask) {
        self.sessionTasksCache[hashKey] = dataTask;
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
        NSString *hashKey = [self hashStringWithAPI:api];
        NSURLSessionDataTask *dataTask = [self.sessionTasksCache objectForKey:hashKey];
        if (dataTask) {
            [self.sessionTasksCache removeObjectForKey:hashKey];
            api.apiSuccessHandler = nil;
            api.apiFailureHandler = nil;
            api.apiProgressHandler = nil;
            api.apiRequestConstructingBodyBlock = nil;
            [dataTask cancel];
        }
    });
}

#pragma mark - private method
- (NSDictionary *)createDebugDictionaryWithAPI:(HLAPI *)api
                                       andTask:(NSURLSessionDataTask *)task
                                      andError:(NSError *)error {
    id mApi, mTask, response, originalRequest, currentRequest, debugError = [NSNull null];
    if (mApi) {
        mApi = [api mutableCopy];
    }
    if (task) {
        mTask = [task mutableCopy];
    }
    if (task.response) {
        response = [task.response mutableCopy];
    }
    if (task.originalRequest) {
        originalRequest = [task.originalRequest mutableCopy];
    }
    if (task.currentRequest) {
        currentRequest = [task.currentRequest mutableCopy];
    }
    if (error) {
        debugError = [error mutableCopy];
    }
    return @{kHLAPIDebugKey: mApi,
             kHLSessionTaskDebugKey: mTask,
             kHLResponseDebugKey: response,
             kHLOriginalRequestDebugKey: originalRequest,
             kHLCurrentRequestDebugKey: currentRequest,
             kHLErrorDebugKey: debugError};
}

- (NSString *)hashStringWithAPI:(HLAPI *)api {
    return [NSString stringWithFormat:@"%lu", (unsigned long)[api hash]];
}

#pragma mark - Network Response Observer
- (void)registerNetworkResponseObserver:(nonnull id<HLAPIResponseDelegate>)observer {
    [self.responseObservers addObject:observer];
}

- (void)removeNetworkResponseObserver:(nonnull id<HLAPIResponseDelegate>)observer {
    if ([self.responseObservers containsObject:observer]) {
        [self.responseObservers removeObject:observer];
    }
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

#pragma mark - sharedManager Static Method
+ (HLAPIManager *)sharedManager {
    static HLAPIManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

+ (void)sendAPIRequest:(nonnull HLAPI *)api {
    return [[self sharedManager] sendAPIRequest:api];
}

+ (void)cancelAPIRequest:(HLAPI *)api {
    return [[self sharedManager] cancelAPIRequest:api];
}

+ (void)sendBatchAPIRequests:(HLAPIBatchRequests *)apis {
    return [[self sharedManager] sendBatchAPIRequests:apis];
}

+ (void)sendChainAPIRequests:(HLAPIChainRequests *)apis {
    return [[self sharedManager] sendChainAPIRequests:apis];
}

+ (void)registerNetworkResponseObserver:(id<HLAPIResponseDelegate>)observer {
    return [[self sharedManager] registerNetworkResponseObserver:observer];
}

+ (void)removeNetworkResponseObserver:(id<HLAPIResponseDelegate>)observer {
    return [[self sharedManager] removeNetworkResponseObserver:observer];
}

+ (void)registerNetworkErrorObserver:(id<HLNetworkErrorProtocol>)observer {
    return [[self sharedManager] registerNetworkErrorObserver:observer];
}

+ (void)removeNetworkErrorObserver:(id<HLNetworkErrorProtocol>)observer {
    return [[self sharedManager] removeNetworkErrorObserver:observer];
}

#pragma mark - reachability
- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}

- (BOOL)isReachableViaWWAN {
    return self.reachabilityStatus == HLReachabilityStatusReachableViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return self.reachabilityStatus == HLReachabilityStatusReachableViaWiFi;
}

+ (void)networkListening:(void (^)(HLReachabilityStatus))listener {
    [[self sharedManager] networkListeningWithDomain:[self sharedManager].config.baseURL listeningBlock:listener];
}

+ (void)stopListening {
    [[self sharedManager] stopListeningWithDomain:[self sharedManager].config.baseURL];
}

- (void)networkListeningWithDomain:(NSString *)domain listeningBlock:(void (^)(HLReachabilityStatus))listener {
    if (self.config.enableReachability) {
        AFNetworkReachabilityManager *manager = [self.reachabilities objectForKey:domain];
        if (!manager) {
            manager = [AFNetworkReachabilityManager managerForDomain:domain];
            self.reachabilities[domain] = manager;
        }
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            HLReachabilityStatus result = HLReachabilityStatusUnknown;
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    result = HLReachabilityStatusUnknown;
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    result = HLReachabilityStatusNotReachable;
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    result = HLReachabilityStatusReachableViaWWAN;
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    result = HLReachabilityStatusReachableViaWiFi;
                    break;
                default:
                    result = HLReachabilityStatusUnknown;
                    break;
            }
            self.reachabilityStatus = result;
            if (listener) {
                listener(result);
            }
        }];
        [manager startMonitoring];
    }
}

- (void)stopListeningWithDomain:(NSString *)domain {
    AFNetworkReachabilityManager *manager = [self.reachabilities objectForKey:domain];
    if (manager) {
        [manager stopMonitoring];
    }
}

@end
