//
//  HLNetworkEngine.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/22.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

#import "HLNetworkEngine.h"
#import "HLNetworkMacro.h"
#import "HLNetworkConst.h"
#import "HLNetworkConfig.h"
#import "HLURLRequest_InternalParams.h"
#import "HLAPIRequest_InternalParams.h"
#import "HLTaskRequest_InternalParams.h"

@interface HLNetworkEngine ()
@property (nonatomic, strong) NSMutableDictionary *sessionManagerCache;
@property (nonatomic, strong) NSMutableDictionary *sessionTasksCache;
@property (nonatomic, strong) NSMutableDictionary *resumePathCache;
@property (nonatomic, strong) NSMutableDictionary <NSString *, AFNetworkReachabilityManager *> *reachabilities;
@end

@implementation HLNetworkEngine
- (instancetype)init {
    self = [super init];
    if (self) {
        _reachabilities = [NSMutableDictionary dictionary];
        _sessionManagerCache = [NSMutableDictionary dictionary];
        _sessionTasksCache = [NSMutableDictionary dictionary];
        _resumePathCache = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (HLNetworkEngine *)sharedEngine {
    static HLNetworkEngine *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

#pragma mark - 获取AFHTTPSessionManager
/**
 根据请求对象获取AFSessionManager

 @param requestObject 请求对象
 @param config 请求参数
 @return AFURLSessionManager
 */
- (AFURLSessionManager *)sessionManagerByRequest:(id)requestObject andManagerConfig:(HLNetworkConfig *)config {
    if (!requestObject) return nil;
    /** 拼接baseUrlStr */
    NSString *baseUrlStr;
    // 如果定义了自定义的cURL, 则直接使用
    NSURL *cURL = [NSURL URLWithString:[requestObject customURL]];
    if (cURL.host) {
        baseUrlStr = [NSString stringWithFormat:@"%@://%@", cURL.scheme ?: @"https", cURL.host];
    } else {
        NSAssert([requestObject baseURL] != nil || config.request.baseURL != nil,
                 @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
        
        NSString *tmpStr = (NSString *)[requestObject baseURL] ? : config.request.baseURL;
        
        // 在某些情况下，一些用户会直接把整个url地址写进 baseUrl
        // 因此，还需要对baseUrl 进行一次切割
        NSURL *tmpURL = [NSURL URLWithString:tmpStr];
        baseUrlStr = [NSString stringWithFormat:@"%@://%@", tmpURL.scheme ?: @"https", tmpURL.host];;
    }
    
    /** 设置AFSecurityPolicy参数 */
    HLSecurityPolicyConfig *requestSecurityPolicy = (HLSecurityPolicyConfig *)[requestObject securityPolicy];
    NSUInteger pinningMode = requestSecurityPolicy.SSLPinningMode ?: config.defaultSecurityPolicy.SSLPinningMode;
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:pinningMode];
    securityPolicy.allowInvalidCertificates = requestSecurityPolicy.allowInvalidCertificates ?: config.defaultSecurityPolicy.allowInvalidCertificates;
    securityPolicy.validatesDomainName = requestSecurityPolicy.validatesDomainName ?: config.defaultSecurityPolicy.validatesDomainName;
    NSString *cerPath = requestSecurityPolicy.cerFilePath ?: config.defaultSecurityPolicy.cerFilePath;
    NSData *certData = nil;
    if (cerPath && ![cerPath isEqualToString:@""]) {
        certData = [NSData dataWithContentsOfFile:cerPath];
        if (certData) {
            securityPolicy.pinnedCertificates = [NSSet setWithObject:certData];
        }
    }
    
    /** 如果requestObject为HLTask */
    if ([requestObject isKindOfClass:[HLTaskRequest class]]) {
        // AFURLSessionManager
        AFURLSessionManager *sessionManager;
        sessionManager = [self.sessionManagerCache objectForKey:baseUrlStr];
        // 如果缓存中取不到对应的sessionManager，则创建一个新的SessionManager
        if (!sessionManager) {
            NSURLSessionConfiguration *sessionConfig;
            if (config) {
                if (config.policy.isBackgroundSession) {
                    NSString *kBackgroundSessionID = [NSString stringWithFormat:@"com.wangshiyu13.backgroundSession.task.%@", baseUrlStr];
                    NSString *kSharedContainerIdentifier = config.policy.AppGroup ?: [NSString stringWithFormat:@"com.wangshiyu13.testApp"];
                    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionID];
                    sessionConfig.sharedContainerIdentifier = kSharedContainerIdentifier;
                } else {
                    sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                }
                sessionConfig.HTTPMaximumConnectionsPerHost = config.request.maxHttpConnectionPerHost;
            } else {
                sessionConfig.HTTPMaximumConnectionsPerHost = MAX_HTTP_CONNECTION_PER_HOST;
            }
            sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfig];
            [self.sessionManagerCache setObject:sessionManager forKey:baseUrlStr];
        }
        sessionManager.securityPolicy = securityPolicy;
        return sessionManager;
    
    /** 如果requestObject为HLAPI */
    } else if ([requestObject isKindOfClass:[HLAPIRequest class]]) {
        // Request 序列化
        AFHTTPRequestSerializer *requestSerializer;
        switch ([requestObject requestSerializerType]) {
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
        requestSerializer.cachePolicy          = [requestObject cachePolicy];
        requestSerializer.timeoutInterval      = [requestObject timeoutInterval];
        NSDictionary *requestHeaderFieldParams = [requestObject header];
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
        switch ([requestObject responseSerializerType]) {
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
        responseSerializer.acceptableContentTypes = [requestObject accpetContentTypes];
        if (!responseSerializer) {
            return nil;
        }
        
        // AFHTTPSession
        AFHTTPSessionManager *sessionManager = [self.sessionManagerCache objectForKey:baseUrlStr];
        if (!sessionManager) {
            // 根据传入的BaseURL创建新的SessionManager
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.HTTPMaximumConnectionsPerHost = config.request.maxHttpConnectionPerHost;
            sessionConfig.requestCachePolicy = [requestObject cachePolicy] ?: config.policy.cachePolicy;
            sessionConfig.timeoutIntervalForRequest = [requestObject timeoutInterval] ?: config.request.requestTimeoutInterval;
            sessionConfig.URLCache = config.policy.URLCache;
            sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrlStr] sessionConfiguration:sessionConfig];
            [self.sessionManagerCache setObject:sessionManager forKey:baseUrlStr];
        }
        sessionManager.requestSerializer = requestSerializer;
        sessionManager.responseSerializer = responseSerializer;
        sessionManager.securityPolicy = securityPolicy;
        
        return sessionManager;
    } else {
        return nil;
    }
}

#pragma mark - 移除sessionTask
- (void)removeTaskForKey:(NSString *)hashKey {
    if ([self.sessionTasksCache objectForKey:hashKey]) {
        [self.sessionTasksCache removeObjectForKey:hashKey];
    }
}

# pragma mark - 发送请求
- (void)sendRequest:(id)requestObject
          andConfig:(HLNetworkConfig *)config
       progressBack:(HLProgressBlock)progressCallBack
           callBack:(HLCallbackBlock)callBack
{
    /** 容错 */
    if (![requestObject isKindOfClass:[HLAPIRequest class]] && ![requestObject isKindOfClass:[HLTaskRequest class]]){
        NSError *noAPIError = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:NSURLErrorUnsupportedURL
                                              userInfo:@{NSLocalizedDescriptionKey: @"请求对象类型不正确！"}];
        if (callBack) {
            callBack(requestObject, nil, noAPIError);
        }
        return;
    }
    if (!requestObject) {
        NSError *noAPIError = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:NSURLErrorUnsupportedURL
                                              userInfo:@{NSLocalizedDescriptionKey: @"请求对象不存在！"}];
        if (callBack) {
            callBack(requestObject, nil, noAPIError);
        }
        return;
    }
    
    // 如果缓存中已有当前task，则立即使api返回失败回调，错误信息为frequentRequestErrorStr
    if ([self.sessionTasksCache objectForKey:[requestObject hashKey]]) {
        NSError *cancelError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorCancelled
                                               userInfo:@{NSLocalizedDescriptionKey: config.tips.frequentRequestErrorStr}];
        if (callBack) {
            callBack(requestObject, nil, cancelError);
        }
        return;
    }
    
    /** 必要参数 */
    /** 生成sessionManager */
    AFURLSessionManager *sessionManager = [self sessionManagerByRequest:requestObject andManagerConfig:config];
    if (!sessionManager) {
        NSError *noSessionError = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorUnsupportedURL
                                                  userInfo:@{NSLocalizedDescriptionKey: @"SessionManager无法构建！"}];
        if (callBack) {
            callBack(requestObject, nil, noSessionError);
        }
        return;
    }
    
    /** 生成requestURLString */
    NSString *requestURLString;
    NSString *host;
    // 如果定义了自定义的cURL, 则直接使用
    NSURL *cURL = [NSURL URLWithString:[requestObject customURL]];
    if (cURL) {
        host = [NSString stringWithFormat:@"%@://%@", cURL.scheme, cURL.host];
        requestURLString = cURL.absoluteString;
    } else {
        NSString *tmpBaseURLStr = (NSString *)[requestObject baseURL] ?: config.request.baseURL;
        if ([tmpBaseURLStr hasSuffix:@"/"]) {
            tmpBaseURLStr = [tmpBaseURLStr substringWithRange:NSMakeRange(0, tmpBaseURLStr.length - 1)];
        }
        NSURL *tmpBaseURL = [NSURL URLWithString:tmpBaseURLStr];
        host = [NSString stringWithFormat:@"%@://%@", tmpBaseURL.scheme, tmpBaseURL.host];
        // 使用BaseUrl + apiversion(可选) + path 组成 UrlString
        // 如果有apiVersion且类型不是HLTask时，则在requestUrlStr中插入该参数
        if (IsEmptyValue(config.request.apiVersion) || [requestObject isKindOfClass:[HLTaskRequest class]]) {
            requestURLString = tmpBaseURL.absoluteString;
        } else {
            requestURLString = [NSString stringWithFormat:@"%@/%@", tmpBaseURL.absoluteString, config.request.apiVersion];
        }
        if (!IsEmptyValue([requestObject path])) {
            requestURLString = [NSString stringWithFormat:@"%@/%@", requestURLString, [requestObject path]];
        }
    }
    if (IsEmptyValue(requestURLString)) {
        NSError *noRequestURLError = [NSError errorWithDomain:NSURLErrorDomain
                                                         code:NSURLErrorUnsupportedURL
                                                     userInfo:@{NSLocalizedDescriptionKey: @"requestURLString无法构建！"}];
        if (callBack) {
            callBack(requestObject, nil, noRequestURLError);
        }
        return;
    }
    
    /** 网络状态不好使自动放弃该此请求 */
    // 设置reachbility,监听url为baseURL
    SCNetworkReachabilityRef hostReachable = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
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
        NSError *networkUnreachableError = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:NSURLErrorCannotConnectToHost
                                                           userInfo:@{NSLocalizedDescriptionKey: config.tips.networkNotReachableErrorStr,
                                                                      NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"网络异常，%@ 无法访问", host]}];
        if (callBack) {
            callBack(requestObject, nil, networkUnreachableError);
        }
        return;
    }
    
    /** 根据requestObject类型，发送请求 */
    // requestObject为HLAPI时
    if ([requestObject isKindOfClass:[HLAPIRequest class]]) {
        HLAPIRequest *api = requestObject;
        AFHTTPSessionManager *session = (AFHTTPSessionManager *)sessionManager;
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
            // 移除dataTask缓存
            @hl_strongify(self)
            if (callBack) {
                callBack(api, resultObject, nil);
            }
            [self removeTaskForKey:api.hashKey];
        };
        
        // task失败Block
        void (^failureBlock)(NSURLSessionDataTask * task, NSError * error)
        = ^(NSURLSessionDataTask * task, NSError * error) {
            // 移除dataTask缓存
            @hl_strongify(self)
            if (callBack) {
                callBack(api, nil, error);
            }
            [self removeTaskForKey:api.hashKey];
        };
        
        // 进度Block
        void (^progressBlock)(NSProgress *progress)
        = ^(NSProgress *progress) {
            if (progress.totalUnitCount <= 0) return;
            dispatch_async_main(^{
                if (progressCallBack) {
                    progressCallBack(progress);
                }
                if (api.progressHandler) {
                    api.progressHandler(progress);
                }
            });
        };
        
        // 执行AFN的请求
        NSURLSessionDataTask *dataTask;
        switch (api.requestMethodType) {
            case GET: {
                dataTask =
                [session GET:requestURLString
                  parameters:requestParams
                    progress:progressBlock
                     success:successBlock
                     failure:failureBlock];
            }
                break;
            case DELETE: {
                dataTask =
                [session DELETE:requestURLString
                     parameters:requestParams
                        success:successBlock
                        failure:failureBlock];
            }
                break;
            case PATCH: {
                dataTask =
                [session PATCH:requestURLString
                    parameters:requestParams
                       success:successBlock
                       failure:failureBlock];
            }
                break;
            case PUT: {
                dataTask =
                [session PUT:requestURLString
                  parameters:requestParams
                     success:successBlock
                     failure:failureBlock];
            }
                break;
            case HEAD: {
                dataTask =
                [session HEAD:requestURLString
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
            case POST: {
                if (![api requestConstructingBodyBlock]) {
                    dataTask =
                    [session POST:requestURLString
                       parameters:requestParams
                         progress:progressBlock
                          success:successBlock
                          failure:failureBlock];
                } else {
                    void (^formDataBlock)(id <AFMultipartFormData> formData)
                    = ^(id <AFMultipartFormData> formData) {
                        api.requestConstructingBodyBlock((id<HLMultipartFormDataProtocol>)formData);
                    };
                    dataTask = [session POST:requestURLString
                                  parameters:requestParams
                   constructingBodyWithBlock:formDataBlock
                                    progress:progressBlock
                                     success:successBlock
                                     failure:failureBlock];
                }
            }
                break;
            default: {
                dataTask =
                [session GET:requestURLString
                  parameters:requestParams
                    progress:progressBlock
                     success:successBlock
                     failure:failureBlock];
            }
                break;
        }
        
        // 缓存dataTask
        if (dataTask) {
            self.sessionTasksCache[api.hashKey] = dataTask;
        }
        
        
    // requestObject为HLTask时
    } else if ([requestObject isKindOfClass:[HLTaskRequest class]]) {
        /** 准备请求参数 */
        HLTaskRequest *task = requestObject;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURLString]];
        __block NSURL *fileURL = task.filePath ? [NSURL fileURLWithPath:task.filePath] : nil;
        if (!fileURL) {
            return;
        }
        
        /** 生成需要的Block */
        // 进度Block
        void (^progressBlock)(NSProgress *progress)
        = ^(NSProgress *progress) {
            if (progress.totalUnitCount <= 0) return;
            if (progressCallBack) {
                progressCallBack(progress);
            }
            if (task.progressHandler) {
                task.progressHandler(progress);
            }
        };
        
        /**
         下载地址Block
         
         param targetPath 目标地址
         param response   对象
         
         return 保存的地址
         */
        NSURL * (^destinationBlock)(NSURL *targetPath, NSURLResponse *response)
        = ^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:response.suggestedFilename];
            return fileURL ?: [NSURL fileURLWithPath:path];
        };
        
        @hl_weakify(self);
        void (^uploadCompleteBlock)(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error)
        = ^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            @hl_strongify(self);
            if (callBack) {
                callBack(task, responseObject, error);
            }
            [self removeTaskForKey:task.hashKey];
        };
        
        void (^donwloadCompleteBlcok)(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error)
        = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            @hl_strongify(self);
            if (callBack) {
                callBack(task, filePath, error);
            }
            [self removeTaskForKey:task.hashKey];
        };
        
        NSURLSessionTask *sessionTask;
        switch (task.requestTaskType) {
            case Upload:
                sessionTask = [sessionManager uploadTaskWithRequest:request
                                                        fromFile:fileURL
                                                        progress:progressBlock
                                               completionHandler:uploadCompleteBlock];
                break;
            case Download: {
                NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:task.resumePath]];
                if (data) {
                    sessionTask = [sessionManager downloadTaskWithResumeData:data
                                                                 progress:progressBlock
                                                              destination:destinationBlock
                                                        completionHandler:donwloadCompleteBlcok];
                } else {
                    sessionTask = [sessionManager downloadTaskWithRequest:request
                                                              progress:progressBlock
                                                           destination:destinationBlock
                                                     completionHandler:donwloadCompleteBlcok];
                }
                self.resumePathCache[@(sessionTask.hash)] = task.resumePath;
            }
                break;
            default: break;
        }
        
        // 缓存dataTask
        if (sessionTask) {
            [sessionTask resume];
            self.sessionTasksCache[task.hashKey] = sessionTask;
        }
    } else {
        return;
    }
}

- (void)cancelRequestByIdentifier:(NSString *)identifier {
    NSURLSessionTask *sessionTask = [self.sessionTasksCache objectForKey:identifier];
    if (sessionTask) {
        if ([sessionTask isKindOfClass:[NSURLSessionDownloadTask class]]) {
            NSURLSessionDownloadTask * downloadTask = (NSURLSessionDownloadTask *)sessionTask;
            [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                [resumeData writeToFile:self.resumePathCache[@(downloadTask.hash)] atomically:YES];
            }];
        } else {
            [sessionTask cancel];
        }
        [self.sessionTasksCache removeObjectForKey:identifier];
    }
}

- (NSURLSessionTask *)requestByIdentifier:(NSString *)identifier {
    return [self.sessionTasksCache objectForKey:identifier] ?: [NSNull null];
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

@interface NSURLSessionDownloadTask ()

@end
