
//  HLAPIManager.m
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/17.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "HLAPIManager.h"
#import "HLURLResponse.h"
#import "HLNetworkMacro.h"
#import "HLSecurityPolicyConfig.h"
#import "HLAPIResponseDelegate.h"
#import "HLMultipartFormDataProtocol.h"
#import "HLNetworkErrorProtocol.h"
#import "HLNetworkConfig.h"
#import "HLAPI.h"
#import "HLAPI_InternalParams.h"
#import "HLAPIBatchRequests.h"
#import "HLAPIChainRequests.h"
#import "HLNetworkLogger.h"

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
        dispatch_queue_create("com.qkhl.networking.wangshiyu13.api.callback.queue", DISPATCH_QUEUE_PRIORITY_DEFAULT);
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
@property (nonatomic, strong) dispatch_queue_t currentQueue;
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
        _currentQueue = _config.request.apiCallbackQueue ?: qkhl_api_http_creation_queue();
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
    self.currentQueue = self.config.request.apiCallbackQueue ?: qkhl_api_http_creation_queue();
}

+ (void)setupConfig:(void (^)(HLNetworkConfig * _Nonnull config))configBlock {
    [[self sharedManager] setupConfig:configBlock];
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
            requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
    }
    requestSerializer.cachePolicy          = api.cachePolicy;
    requestSerializer.timeoutInterval      = api.timeoutInterval;
    NSDictionary *requestHeaderFieldParams = api.header;
    if (![[requestHeaderFieldParams allKeys] containsObject:@"User-Agent"] &&
        self.config.request.userAgent) {
        [requestSerializer setValue:self.config.request.userAgent forHTTPHeaderField:@"User-Agent"];
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
    if (cURL.host) {
        baseUrlStr = [NSString stringWithFormat:@"%@://%@", cURL.scheme ?: @"https", cURL.host];
    } else {
        NSAssert(api.baseURL != nil || self.config.request.baseURL != nil,
                 @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
        
        NSString *tmpStr = api.baseURL ? : self.config.request.baseURL;
        
        // 在某些情况下，一些用户会直接把整个url地址写进 baseUrl
        // 因此，还需要对baseUrl 进行一次切割
        NSURL *tmpURL = [NSURL URLWithString:tmpStr];
        baseUrlStr = [NSString stringWithFormat:@"%@://%@", tmpURL.scheme ?: @"https", tmpURL.host];;
    }
    
    // 设置AFSecurityPolicy参数
    NSUInteger pinningMode = api.securityPolicy.SSLPinningMode ?: self.config.defaultSecurityPolicy.SSLPinningMode;
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:pinningMode];
    
    securityPolicy.allowInvalidCertificates = api.securityPolicy.allowInvalidCertificates ?: self.config.defaultSecurityPolicy.allowInvalidCertificates;
    securityPolicy.validatesDomainName = api.securityPolicy.validatesDomainName ?: self.config.defaultSecurityPolicy.validatesDomainName;
    NSString *cerPath = api.securityPolicy.cerFilePath ?: self.config.defaultSecurityPolicy.cerFilePath;
    NSData *certData = nil;
    if (cerPath && ![cerPath isEqualToString:@""]) {
        certData = [NSData dataWithContentsOfFile:cerPath];
        if (certData) {
            securityPolicy.pinnedCertificates = [NSSet setWithObject:certData];
        }
    }
    
    // AFHTTPSession
    AFHTTPSessionManager *sessionManager = [self.sessionManagerCache objectForKey:baseUrlStr];
    if (!sessionManager) {
        // 根据传入的BaseURL创建新的SessionManager
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.HTTPMaximumConnectionsPerHost = self.config.request.maxHttpConnectionPerHost;
        sessionConfig.requestCachePolicy = api.cachePolicy ?: self.config.policy.cachePolicy;
        sessionConfig.timeoutIntervalForRequest = api.timeoutInterval ?: self.config.request.requestTimeoutInterval;
        sessionConfig.URLCache = self.config.policy.URLCache;
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

 @param api 调用的API
 @param resultObject 请求的返回结果
 @param error 请求返回的错误
 @param semaphore 信号量
 @param task NSURLSessionDataTask
 */
- (void)callbackWithRequest:(HLAPI *)api
            andResultObject:(id)resultObject
                   andError:(NSError *)error
                   andGroup:(dispatch_group_t)group
               andSemaphore:(dispatch_semaphore_t)semaphore
                andDataTask:(NSURLSessionDataTask *)task
{
    // 处理回调的block
    NSError *netError = error;
    if (netError) {
        // 网络状态不好时自动重试
        /**
         NS_ENUM(NSInteger)
         {
         NSURLErrorUnknown = 			-1,
         NSURLErrorCancelled = 			-999,
         NSURLErrorBadURL = 				-1000,
         NSURLErrorTimedOut = 			-1001,
         NSURLErrorUnsupportedURL = 			-1002,
         NSURLErrorCannotFindHost = 			-1003,
         NSURLErrorCannotConnectToHost = 		-1004,
         NSURLErrorNetworkConnectionLost = 		-1005,
         NSURLErrorDNSLookupFailed = 		-1006,
         NSURLErrorHTTPTooManyRedirects = 		-1007,
         NSURLErrorResourceUnavailable = 		-1008,
         NSURLErrorNotConnectedToInternet = 		-1009,
         NSURLErrorRedirectToNonExistentLocation = 	-1010,
         NSURLErrorBadServerResponse = 		-1011,
         NSURLErrorUserCancelledAuthentication = 	-1012,
         NSURLErrorUserAuthenticationRequired = 	-1013,
         NSURLErrorZeroByteResource = 		-1014,
         NSURLErrorCannotDecodeRawData =             -1015,
         NSURLErrorCannotDecodeContentData =         -1016,
         NSURLErrorCannotParseResponse =             -1017,
         NSURLErrorAppTransportSecurityRequiresSecureConnection NS_ENUM_AVAILABLE(10_11, 9_0) = -1022,
         NSURLErrorFileDoesNotExist = 		-1100,
         NSURLErrorFileIsDirectory = 		-1101,
         NSURLErrorNoPermissionsToReadFile = 	-1102,
         NSURLErrorDataLengthExceedsMaximum NS_ENUM_AVAILABLE(10_5, 2_0) =	-1103,
         
         // SSL errors
         NSURLErrorSecureConnectionFailed = 		-1200,
         NSURLErrorServerCertificateHasBadDate = 	-1201,
         NSURLErrorServerCertificateUntrusted = 	-1202,
         NSURLErrorServerCertificateHasUnknownRoot = -1203,
         NSURLErrorServerCertificateNotYetValid = 	-1204,
         NSURLErrorClientCertificateRejected = 	-1205,
         NSURLErrorClientCertificateRequired =	-1206,
         NSURLErrorCannotLoadFromNetwork = 		-2000,
         
         // Download and file I/O errors
         NSURLErrorCannotCreateFile = 		-3000,
         NSURLErrorCannotOpenFile = 			-3001,
         NSURLErrorCannotCloseFile = 		-3002,
         NSURLErrorCannotWriteToFile = 		-3003,
         NSURLErrorCannotRemoveFile = 		-3004,
         NSURLErrorCannotMoveFile = 			-3005,
         NSURLErrorDownloadDecodingFailedMidStream = -3006,
         NSURLErrorDownloadDecodingFailedToComplete =-3007,
         
         NSURLErrorInternationalRoamingOff NS_ENUM_AVAILABLE(10_7, 3_0) =         -1018,
         NSURLErrorCallIsActive NS_ENUM_AVAILABLE(10_7, 3_0) =                    -1019,
         NSURLErrorDataNotAllowed NS_ENUM_AVAILABLE(10_7, 3_0) =                  -1020,
         NSURLErrorRequestBodyStreamExhausted NS_ENUM_AVAILABLE(10_7, 3_0) =      -1021,
         
         NSURLErrorBackgroundSessionRequiresSharedContainer NS_ENUM_AVAILABLE(10_10, 8_0) = -995,
         NSURLErrorBackgroundSessionInUseByAnotherProcess NS_ENUM_AVAILABLE(10_10, 8_0) = -996,
         NSURLErrorBackgroundSessionWasDisconnected NS_ENUM_AVAILABLE(10_10, 8_0)= -997,
         };
         
         */
        if (error.code == NSURLErrorCannotConnectToHost) {
            if (api.retryCount > 0) {
                api.retryCount --;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self sendRequest:api withSemaphore:semaphore atGroup:group];
                });
                return;
            }
        }
        // 如果不是reachability无法访问host或用户取消错误(NSURLErrorCancelled)，则对错误提示进行处理
        if (![error.domain isEqualToString: NSURLErrorDomain] &&
            error.code != NSURLErrorCancelled) {
            // 使用KVC修改error内部属性
            // 默认使用self.config.generalErrorTypeStr = "服务器连接错误，请稍候重试"
            NSMutableDictionary *tmpUserInfo = [[NSMutableDictionary alloc]initWithDictionary:error.userInfo copyItems:NO];
            if (![[tmpUserInfo allKeys] containsObject:NSLocalizedFailureReasonErrorKey]) {
                tmpUserInfo[NSLocalizedFailureReasonErrorKey] = NSLocalizedString(self.config.tips.generalErrorTypeStr, nil);
            }
            if (![[tmpUserInfo allKeys] containsObject:NSLocalizedRecoverySuggestionErrorKey]) {
                tmpUserInfo[NSLocalizedRecoverySuggestionErrorKey] = NSLocalizedString(self.config.tips.generalErrorTypeStr, nil);
            }
            // 加上 networking error code
            NSString *newErrorDescription = self.config.tips.generalErrorTypeStr;
            if (self.config.policy.isErrorCodeDisplayEnabled) {
                newErrorDescription = [NSString stringWithFormat:@"%@, error code = (%ld)", self.config.tips.generalErrorTypeStr, (long)error.code];
            }
            tmpUserInfo[NSLocalizedDescriptionKey] = NSLocalizedString(newErrorDescription, nil);
            NSDictionary *userInfo = [tmpUserInfo copy];
            netError = [NSError errorWithDomain:error.domain
                                        code:error.code
                                    userInfo:userInfo];
        }
    }
    // 处理数据转换
    if ([api objReformerDelegate]) {
        resultObject = [api.objReformerDelegate objReformerWithAPI:api andResponseObject:resultObject andError:netError];
    }
    
    // 生成response对象
    HLURLResult *result = [[HLURLResult alloc] initWithObject:resultObject andError:netError];
    HLURLResponse *response = [[HLURLResponse alloc] initWithResult:result
                                                          requestId:[NSNumber numberWithUnsignedInteger:[api hash]]
                                                            request:task.currentRequest];
    
    // 设置Debug及log信息
    HLDebugMessage *msg = [self createDebugMessageWithAPI:api
                                                  andTask:task
                                              andResponse:response];
#if DEBUG
    if ([api apiDebugHandler]) {
        dispatch_async_main(api.apiDebugHandler(msg);
                            api.apiDebugHandler = nil;)
    }
    if (self.config.enableGlobalLog) {
        [HLNetworkLogger logInfoWithDebugMessage:msg];
    }
#endif
    [HLNetworkLogger addLogInfoWithDebugMessage:msg];
    
    if (netError) {
        for (id<HLNetworkErrorProtocol> observer in self.errorObservers) {
            [observer networkErrorInfo:netError];
        }
        if ([api apiFailureHandler]) {
            dispatch_async_main(api.apiFailureHandler(netError);
                                api.apiFailureHandler = nil;)
        }
    } else {
        if ([api apiSuccessHandler]) {
            NSLog(@"%@", [NSThread currentThread]);
            if ([NSThread isMainThread]) {
                api.apiSuccessHandler(resultObject);
                api.apiSuccessHandler = nil;
            } else {
                dispatch_async_main(api.apiSuccessHandler(resultObject);
                                    api.apiSuccessHandler = nil;)
            }
        }
    }
    
    // 处理回调的delegate
    for (id<HLAPIResponseDelegate> observer in self.responseObservers) {
        dispatch_async_main(if ([observer.requestAPIs containsObject:api]) {
            if (netError) {
                if ([observer respondsToSelector:@selector(requestFailureWithResponseError:atAPI:)]) {
                    [observer requestFailureWithResponseError:netError atAPI:api];
                }
            } else {
                if ([observer respondsToSelector:@selector(requestSucessWithResponseObject:atAPI:)]) {
                    [observer requestSucessWithResponseObject:resultObject atAPI:api];
                }
            }
        })
    }
    
    // 完成后离组
    if (group) {
        dispatch_group_leave(group);
    }
    // 完成后信号量加1
    if (semaphore) {
        dispatch_semaphore_signal(semaphore);
    }
    NSString *hashKey = [self hashStringWithAPI:api];
    if ([self.sessionTasksCache objectForKey:hashKey]) {
        [self.sessionTasksCache removeObjectForKey:hashKey];
    }
}

#pragma mark - Send Request
- (void)sendRequest:(HLAPI *)api
      withSemaphore:(dispatch_semaphore_t)semaphore
            atGroup:(dispatch_group_t)group
{
    NSParameterAssert(api);
    AFHTTPSessionManager *sessionManager = [self sessionManagerWithAPI:api];
    if (!sessionManager) {
        return;
    }
    
    @hl_weakify(self);
    NSString *requestURLString;
    // 如果定义了自定义的cURL, 则直接使用
    NSURL *cURL = [NSURL URLWithString:api.cURL];
    if (cURL) {
        requestURLString = cURL.absoluteString;
    } else {
        NSAssert(api.baseURL != nil || self.config.request.baseURL != nil,
                 @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
        NSString *tmpBaseURLStr = api.baseURL ?: self.config.request.baseURL;
        NSURL *tmpBaseURL = [NSURL URLWithString:tmpBaseURLStr];
        // 使用BaseUrl + apiversion(可选) + path 组成 UrlString
        // 如果有apiVersion，则在requestUrlStr中插入该参数
        if (self.config.request.apiVersion && ![self.config.request.apiVersion isEqualToString:@""]) {
            requestURLString = [NSString stringWithFormat:@"%@/%@", tmpBaseURL.absoluteString, self.config.request.apiVersion];
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
    if (self.config.request.defaultParams && api.useDefaultParams) {
        [requestParams addEntriesFromDictionary:self.config.request.defaultParams];
    }
    
    NSString *hashKey = [self hashStringWithAPI:api];
    // 如果缓存中已有当前task，则立即使api返回失败回调，错误信息为frequentRequestErrorStr
    if ([self.sessionTasksCache objectForKey:hashKey]) {
        NSString *errorStr     = self.config.tips.frequentRequestErrorStr;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr
                                   };
        NSError *cancelError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorCancelled
                                               userInfo:userInfo];
        [self callbackWithRequest:api andResultObject:nil andError:cancelError andGroup:group andSemaphore:semaphore andDataTask:nil];
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
    
    // 如果无网络，则立即使api响应失败回调，错误信息是networkNotReachableErrorStr
    if (!isReachable) {
        NSString *errorStr     = self.config.tips.networkNotReachableErrorStr;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr,
                                   NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"网络异常，%@ 无法访问", sessionManager.baseURL.host]
                                   };
        NSError *networkUnreachableError = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:NSURLErrorCannotConnectToHost
                                                           userInfo:userInfo];
        NSLog(@"%@失败", hashKey);
        [self callbackWithRequest:api andResultObject:nil andError:networkUnreachableError andGroup:group andSemaphore:semaphore andDataTask:nil];
        return;
    }
    
    /**
     task成功Block
     */
    void (^successBlock)(NSURLSessionDataTask *task, id responseObject)
    = ^(NSURLSessionDataTask * task, id resultObject) {
        @hl_strongify(self);
        if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        [self callbackWithRequest:api
                  andResultObject:resultObject
                         andError:nil
                         andGroup:group
                     andSemaphore:semaphore
                      andDataTask:task];
    };
    
    /**
     task失败Block
     */
    void (^failureBlock)(NSURLSessionDataTask * task, NSError * error)
    = ^(NSURLSessionDataTask * task, NSError * error) {
        @hl_strongify(self);
        if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        [self callbackWithRequest:api
                  andResultObject:nil
                         andError:error
                         andGroup:group
                     andSemaphore:semaphore
                      andDataTask:task];
    };
    
    /**
     进度Block
     */
    void (^progressBlock)(NSProgress *progress)
    = api.apiProgressHandler ? ^(NSProgress *progress) {
        if (progress.totalUnitCount <= 0) {
            return;
        }
        dispatch_async_main(api.apiProgressHandler(progress);
                            for (id<HLAPIResponseDelegate> obj in self.responseObservers) {
                                if ([obj respondsToSelector:@selector(requestProgress:atAPI:)]) {
                                    [obj requestProgress:progress atAPI:api];
                                }
                            })
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
    
    if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
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
                                 dispatch_async_main(successBlock(task, nil);)
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

/**
 发送单个API
 
 @param api 需要发送的API
 */
- (void)send:(nonnull HLAPI *)api {
    @hl_weakify(self);
    dispatch_async(self.currentQueue, ^{
        @hl_strongify(self);
        [self sendRequest:api withSemaphore:nil atGroup:nil];
    });
}

- (void)cancel:(nonnull HLAPI *)api {
    @hl_weakify(self);
    dispatch_async(self.currentQueue, ^{
        @hl_strongify(self);
        NSString *hashKey = [self hashStringWithAPI:api];
        NSURLSessionDataTask *dataTask = [self.sessionTasksCache objectForKey:hashKey];
        if (dataTask) {
            [self.sessionTasksCache removeObjectForKey:hashKey];
            api.apiSuccessHandler = nil;
            api.apiFailureHandler = nil;
            api.apiProgressHandler = nil;
            api.apiDebugHandler = nil;
            api.apiRequestConstructingBodyBlock = nil;
            [dataTask cancel];
        }
    });
}

#pragma mark - Send Sync Chain Requests

/**
 使用信号量做同步请求
 
 @param apis api集合
 */
- (void)sendChain:(nonnull HLAPIChainRequests *)apis {
    NSParameterAssert(apis);
    dispatch_queue_t queue;
    if (apis.customChainQueue) {
        queue = apis.customChainQueue;
    } else {
        queue = self.currentQueue;
    }
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_group_t chain_api_group = dispatch_group_create();
    @hl_weakify(self);
    dispatch_async(queue, ^{
        [apis enumerateObjectsUsingBlock:^(HLAPI * _Nonnull api, NSUInteger idx, BOOL * _Nonnull stop) {
            @hl_strongify(self);
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_group_enter(chain_api_group);
            AFHTTPSessionManager *sessionManager = [self sessionManagerWithAPI:api];
            if (!sessionManager) {
                dispatch_group_leave(chain_api_group);
                *stop = YES;
            }
            sessionManager.completionGroup = chain_api_group;
            [self sendRequest:api withSemaphore:semaphore atGroup:chain_api_group];
        }];
        dispatch_group_notify(chain_api_group, dispatch_get_main_queue(), ^{
            if (apis.delegate) {
                [apis.delegate chainRequestsAllDidFinished:apis];
            }
        });
    });
}

#pragma mark - Send Batch Requests
- (void)sendBatch:(nonnull HLAPIBatchRequests *)apis {
    NSParameterAssert(apis);
    dispatch_group_t batch_api_group = dispatch_group_create();
    @hl_weakify(self);
    dispatch_async(self.currentQueue, ^{
        [apis enumerateObjectsUsingBlock:^(HLAPI *api, BOOL *stop) {
            @hl_strongify(self);
            dispatch_group_enter(batch_api_group);
            AFHTTPSessionManager *sessionManager = [self sessionManagerWithAPI:api];
            if (!sessionManager) {
                dispatch_group_leave(batch_api_group);
                *stop = YES;
            }
            sessionManager.completionGroup = batch_api_group;
            
            [self sendRequest:api withSemaphore:nil atGroup:batch_api_group];
        }];
        dispatch_group_notify(batch_api_group, dispatch_get_main_queue(), ^{
            if (apis.delegate) {
                [apis.delegate batchAPIRequestsDidFinished:apis];
            }
        });
    });
}

#pragma mark - private method
- (HLDebugMessage *)createDebugMessageWithAPI:(HLAPI *)api
                                      andTask:(NSURLSessionDataTask *)task
                                  andResponse:(HLURLResponse *)response
{
    id mTask = [NSNull null];
    id mResponse = [NSNull null];
    
    if (task) mTask = task;
    if (response) mResponse = response;
    
    NSDictionary *params = @{kHLRequestDebugKey: api,
                             kHLSessionTaskDebugKey: mTask,
                             kHLResponseDebugKey: response,
                             kHLQueueDebugKey: self.currentQueue};
    return [[HLDebugMessage alloc] initWithDict:params];
}

- (NSString *)hashStringWithAPI:(HLAPI *)api {
    return [NSString stringWithFormat:@"%lu", (unsigned long)[api hash]];
}

#pragma mark - Network Response Observer
- (void)registerResponseObserver:(nonnull id<HLAPIResponseDelegate>)observer {
    [self.responseObservers addObject:observer];
}

- (void)removeResponseObserver:(nonnull id<HLAPIResponseDelegate>)observer {
    if ([self.responseObservers containsObject:observer]) {
        [self.responseObservers removeObject:observer];
    }
}

#pragma mark - Network Error Observer
- (void)registerErrorObserver:(nonnull id<HLNetworkErrorProtocol>)observer {
    [self.errorObservers addObject:observer];
}

- (void)removeErrorObserver:(nonnull id<HLNetworkErrorProtocol>)observer {
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

+ (void)send:(nonnull HLAPI *)api {
    return [[self sharedManager] send:api];
}

+ (void)cancel:(HLAPI *)api {
    return [[self sharedManager] cancel:api];
}

+ (void)sendBatch:(HLAPIBatchRequests *)apis {
    return [[self sharedManager] sendBatch:apis];
}

+ (void)sendChain:(HLAPIChainRequests *)apis {
    return [[self sharedManager] sendChain:apis];
}

+ (void)registerResponseObserver:(id<HLAPIResponseDelegate>)observer {
    return [[self sharedManager] registerResponseObserver:observer];
}

+ (void)removeResponseObserver:(id<HLAPIResponseDelegate>)observer {
    return [[self sharedManager] removeResponseObserver:observer];
}

+ (void)registerErrorObserver:(id<HLNetworkErrorProtocol>)observer {
    return [[self sharedManager] registerErrorObserver:observer];
}

+ (void)removeErrorObserver:(id<HLNetworkErrorProtocol>)observer {
    return [[self sharedManager] removeErrorObserver:observer];
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

+ (HLReachabilityStatus)reachabilityStatus {
    return [self sharedManager].reachabilityStatus;
}

+ (BOOL)isReachable {
    return [self sharedManager].isReachable;
}

+ (BOOL)isReachableViaWWAN {
    return [self sharedManager].isReachableViaWWAN;
}

+ (BOOL)isReachableViaWiFi {
    return [self sharedManager].isReachableViaWiFi;
}

+ (void)listening:(void (^)(HLReachabilityStatus))listener {
    [[self sharedManager] listeningWithDomain:[self sharedManager].config.request.baseURL listeningBlock:listener];
}

+ (void)stopListening {
    [[self sharedManager] stopListeningWithDomain:[self sharedManager].config.request.baseURL];
}

- (void)listeningWithDomain:(NSString *)domain listeningBlock:(void (^)(HLReachabilityStatus))listener {
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
        [self.reachabilities removeObjectForKey:domain];
    }
}

@end
