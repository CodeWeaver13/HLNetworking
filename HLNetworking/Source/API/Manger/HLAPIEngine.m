//
//  HLAPIEngine.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/22.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

#import "HLAPIEngine.h"
#import "HLAPI.h"
#import "HLAPI_InternalParams.h"
#import "HLNetworkConfig.h"
#import "HLNetworkMacro.h"

@interface HLAPIEngine ()
@property (nonatomic, strong) NSMutableDictionary *sessionManagerCache;
@property (nonatomic, strong) NSMutableDictionary *sessionTasksCache;
@property (nonatomic, strong) NSMutableDictionary <NSString *, AFNetworkReachabilityManager *> *reachabilities;
@end

@implementation HLAPIEngine
- (instancetype)init {
    self = [super init];
    if (self) {
        _reachabilities = [NSMutableDictionary dictionary];
        _sessionManagerCache = [NSMutableDictionary dictionary];
        _sessionTasksCache = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (HLAPIEngine *)sharedEngine {
    static HLAPIEngine *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

#pragma mark - 获取AFHTTPSessionManager
/**
 根据API的BaseURL获取AFSessionManager
 
 @param api 调用的API
 
 @return AFHTTPSessionManager
 */
- (AFHTTPSessionManager *)sessionManagerWithAPI:(HLAPI *)api andManagerConfig:(HLNetworkConfig *)config {
    if (!api) {
        return nil;
    }
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
        config.request.userAgent) {
        [requestSerializer setValue:config.request.userAgent forHTTPHeaderField:@"User-Agent"];
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
        NSAssert(api.baseURL != nil || config.request.baseURL != nil,
                 @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
        
        NSString *tmpStr = api.baseURL ? : config.request.baseURL;
        
        // 在某些情况下，一些用户会直接把整个url地址写进 baseUrl
        // 因此，还需要对baseUrl 进行一次切割
        NSURL *tmpURL = [NSURL URLWithString:tmpStr];
        baseUrlStr = [NSString stringWithFormat:@"%@://%@", tmpURL.scheme ?: @"https", tmpURL.host];;
    }
    
    // 设置AFSecurityPolicy参数
    NSUInteger pinningMode = api.securityPolicy.SSLPinningMode ?: config.defaultSecurityPolicy.SSLPinningMode;
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:pinningMode];
    
    securityPolicy.allowInvalidCertificates = api.securityPolicy.allowInvalidCertificates ?: config.defaultSecurityPolicy.allowInvalidCertificates;
    securityPolicy.validatesDomainName = api.securityPolicy.validatesDomainName ?: config.defaultSecurityPolicy.validatesDomainName;
    NSString *cerPath = api.securityPolicy.cerFilePath ?: config.defaultSecurityPolicy.cerFilePath;
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
        sessionConfig.HTTPMaximumConnectionsPerHost = config.request.maxHttpConnectionPerHost;
        sessionConfig.requestCachePolicy = api.cachePolicy ?: config.policy.cachePolicy;
        sessionConfig.timeoutIntervalForRequest = api.timeoutInterval ?: config.request.requestTimeoutInterval;
        sessionConfig.URLCache = config.policy.URLCache;
        sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrlStr]
                                                  sessionConfiguration:sessionConfig];
        [self.sessionManagerCache setObject:sessionManager forKey:baseUrlStr];
    }
    sessionManager.requestSerializer = requestSerializer;
    sessionManager.responseSerializer = responseSerializer;
    sessionManager.securityPolicy = securityPolicy;
    
    return sessionManager;
}

#pragma mark - 移除Task
- (void)removeTaskForKey:(NSString *)hashKey {
    if ([self.sessionTasksCache objectForKey:hashKey]) {
        [self.sessionTasksCache removeObjectForKey:hashKey];
    }
}

# pragma mark - 发送请求
- (void)sendRequest:(HLAPI *)api
          andConfig:(HLNetworkConfig *)config
       progressBack:(HLProgressBlock)progressCallBack
           callBack:(HLAPICallbackBlock)callBack
{
    // 容错
    if (!api) {
        NSString *errorStr     = @"API不存在！";
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorStr};
        NSError *noAPIError = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:NSURLErrorUnsupportedURL
                                              userInfo:userInfo];
        if (callBack) {
            callBack(api, nil, noAPIError);
        }
        return;
    }
    
    // 如果缓存中已有当前task，则立即使api返回失败回调，错误信息为frequentRequestErrorStr
    if ([self.sessionTasksCache objectForKey:api.hashKey]) {
        NSString *errorStr     = config.tips.frequentRequestErrorStr;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr
                                   };
        NSError *cancelError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorCancelled
                                               userInfo:userInfo];
        if (callBack) {
            callBack(api, nil, cancelError);
        }
        return;
    }
    
    /** 必要参数 */
    /** 生成sessionManager */
    AFHTTPSessionManager *sessionManager = [self sessionManagerWithAPI:api andManagerConfig:config];
    if (!sessionManager) {
        NSString *errorStr     = @"SessionManager无法构建！";
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr
                                   };
        NSError *noSessionError = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorUnsupportedURL
                                                  userInfo:userInfo];
        if (callBack) {
            callBack(api, nil, noSessionError);
        }
        return;
    }
    
    /** 生成requestURLString */
    NSString *requestURLString;
    // 如果定义了自定义的cURL, 则直接使用
    NSURL *cURL = [NSURL URLWithString:api.cURL];
    if (cURL) {
        requestURLString = cURL.absoluteString;
    } else {
        NSString *tmpBaseURLStr = api.baseURL ?: config.request.baseURL;
        NSURL *tmpBaseURL = [NSURL URLWithString:tmpBaseURLStr];
        // 使用BaseUrl + apiversion(可选) + path 组成 UrlString
        // 如果有apiVersion，则在requestUrlStr中插入该参数
        if (IsEmptyValue(config.request.apiVersion)) {
            requestURLString = tmpBaseURL.absoluteString;
        } else {
            requestURLString = [NSString stringWithFormat:@"%@/%@", tmpBaseURL.absoluteString, config.request.apiVersion];
        }
        if (!IsEmptyValue(api.path)) {
            requestURLString = [NSString stringWithFormat:@"%@/%@", requestURLString, api.path];
        }
    }
    if (IsEmptyValue(requestURLString)) return;
    
    /** 生成请求参数 */
    NSMutableDictionary<NSString *, id> *requestParams;
    requestParams = [NSMutableDictionary dictionaryWithDictionary:api.parameters];
    if (config.request.defaultParams && api.useDefaultParams) {
        [requestParams addEntriesFromDictionary:config.request.defaultParams];
    }
    
    /** 生成需要的Block */
    // task成功Block
    @hl_weakify(self)
    void (^successBlock)(NSURLSessionDataTask *task, id responseObject)
    = ^(NSURLSessionDataTask * task, id resultObject) {
        if (config.tips.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        // 移除dataTask缓存
        @hl_strongify(self)
        [self removeTaskForKey:api.hashKey];
        if (callBack) {
            callBack(api, resultObject, nil);
        }
    };
    
    // task失败Block
    void (^failureBlock)(NSURLSessionDataTask * task, NSError * error)
    = ^(NSURLSessionDataTask * task, NSError * error) {
        if (config.tips.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        // 移除dataTask缓存
        @hl_strongify(self)
        [self removeTaskForKey:api.hashKey];
        if (callBack) {
            callBack(api, nil, error);
        }
    };
    
    // 进度Block
    void (^progressBlock)(NSProgress *progress)
    = ^(NSProgress *progress) {
        if (progress.totalUnitCount <= 0) return;
        dispatch_async_main(^{
            if (progressCallBack) {
                progressCallBack(progress);
            }
            if (api.apiProgressHandler) {
                api.apiProgressHandler(progress);
            }
        });
    };
    
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
        NSString *errorStr = config.tips.networkNotReachableErrorStr;
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorStr,
                                   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"网络异常，%@ 无法访问", sessionManager.baseURL.host]};
        NSError *networkUnreachableError = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:NSURLErrorCannotConnectToHost
                                                           userInfo:userInfo];
        if (callBack) {
            callBack(api, nil, networkUnreachableError);
        }
        return;
    }
    
    // 执行AFN的请求
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
                                 dispatch_async_main(^{
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
    
    // 缓存dataTask
    if (dataTask) {
        self.sessionTasksCache[api.hashKey] = dataTask;
    }
}

- (void)cancelRequest:(HLAPI *)api {
    NSURLSessionDataTask *dataTask = [self.sessionTasksCache objectForKey:api.hashKey];
    if (dataTask) {
        api.apiSuccessHandler = nil;
        api.apiFailureHandler = nil;
        api.apiProgressHandler = nil;
        api.apiDebugHandler = nil;
        api.apiRequestConstructingBodyBlock = nil;
        [dataTask cancel];
        [self.sessionTasksCache removeObjectForKey:api.hashKey];
    }
}

- (NSURLSessionDataTask *)requestForAPI:(HLAPI *)api {
    return [self.sessionTasksCache objectForKey:api.hashKey] ?: [NSNull null];
}

- (void)listeningWithDomain:(NSString *)domain listeningBlock:(HLReachabilityBlock)listener {
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
        if (listener) {
            listener(result);
        }
    }];
    [manager startMonitoring];
}

- (void)stopListeningWithDomain:(NSString *)domain {
    AFNetworkReachabilityManager *manager = [self.reachabilities objectForKey:domain];
    if (manager) {
        [manager stopMonitoring];
        if ([self.reachabilities objectForKey:domain]) {
            [self.reachabilities removeObjectForKey:domain];
        }
    }
}

@end
