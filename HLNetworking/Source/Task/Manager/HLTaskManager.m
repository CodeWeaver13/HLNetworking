//
//  HLTaskManager.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/25.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLTaskManager.h"
#import "HLTaskResponseProtocol.h"
#import "HLTask.h"
#import "HLNetworkConfig.h"
#import "HLSecurityPolicyConfig.h"
#import "HLAPIType.h"
#import "AFURLSessionManager.h"

// 创建任务队列
static dispatch_queue_t qkhl_task_session_creation_queue() {
    static dispatch_queue_t qkhl_task_session_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        qkhl_task_session_creation_queue =
        dispatch_queue_create("com.qkhl.pp.networking.wangshiyu13.task.creation", DISPATCH_QUEUE_SERIAL);
    });
    return qkhl_task_session_creation_queue;
}
static HLTaskManager *shared = nil;

@interface HLTaskManager ()
@property (nonatomic, strong) NSCache *sessionManagerCache;
@property (nonatomic, strong) NSCache *sessionTasksCache;
@end

@implementation HLTaskManager
#pragma mark - init method
+ (HLTaskManager *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (!shared) {
        shared = [super init];
        shared.config = [HLNetworkConfig config];
    }
    return shared;
}

#pragma mark - AFURLSessionManager
/**
 根据API的BaseURL创建AFSessionManager
 
 @param task 调用的API
 
 @return AFHTTPSessionManager
 */
- (AFURLSessionManager *)sessionManagerWithTask:(HLTask *)task {
    NSParameterAssert(task);
    
    NSString *baseUrlStr = [self requestBaseURLStringWithTask:task];
    // AFURLSessionManager
    AFURLSessionManager *sessionManager;
    sessionManager = [self.sessionManagerCache objectForKey:baseUrlStr];
    if (!sessionManager) {
        sessionManager = [self newSessionManagerWithTask:task];
        [self.sessionManagerCache setObject:sessionManager forKey:baseUrlStr];
    }
    sessionManager.securityPolicy = [self securityPolicyWithTask:task];
    return sessionManager;
}

/**
 创建新的SessionManager
 
 @return AFHTTPSessionManager
 */
- (AFURLSessionManager *)newSessionManagerWithTask:(HLTask *)task {
    NSURLSessionConfiguration *sessionConfig;
    if (self.config) {
        if (self.config.isBackgroundSession) {
            NSString *kBackgroundSessionID = [NSString stringWithFormat:@"com.wangshiyu13.backgroundSession.task.%@", [self requestBaseURLStringWithTask:task]];
            NSString *kSharedContainerIdentifier = self.config.AppGroup ?: [NSString stringWithFormat:@"com.wangshiyu13.testApp"];
            sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionID];
            sessionConfig.sharedContainerIdentifier = kSharedContainerIdentifier;
        } else {
            sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        sessionConfig.HTTPMaximumConnectionsPerHost = self.config.maxHttpConnectionPerHost;
    } else {
        sessionConfig.HTTPMaximumConnectionsPerHost = MAX_HTTP_CONNECTION_PER_HOST;
    }
    return [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfig];
}

/**
 从task中获取securityPolicy（安全策略）
 
 @param task 调用的API
 
 @return securityPolicy
 */
- (AFSecurityPolicy *)securityPolicyWithTask:(HLTask *)task {
    NSUInteger pinningMode                  = task.securityPolicy.SSLPinningMode;
    AFSecurityPolicy *securityPolicy        = [AFSecurityPolicy policyWithPinningMode:pinningMode];
    securityPolicy.allowInvalidCertificates = task.securityPolicy.allowInvalidCertificates;
    securityPolicy.validatesDomainName      = task.securityPolicy.validatesDomainName;
    return securityPolicy;
}

/**
 从API中获取requestBaseURL
 
 @param task 调用的API
 
 @return baseURL
 */
- (NSString *)requestBaseURLStringWithTask:(HLTask *)task {
    NSParameterAssert(task);
    
    // 如果定义了自定义的cURL, 则直接使用
    if (task.taskURL) {
        NSURL *url  = [NSURL URLWithString:task.taskURL];
        NSURL *root = [NSURL URLWithString:@"/" relativeToURL:url];
        return [NSString stringWithFormat:@"%@", root.absoluteString];
    }
    
    NSAssert(task.baseURL != nil || self.config.baseURL != nil,
             @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
    
    NSString *baseURL = task.baseURL ? : self.config.baseURL;
    
    // 在某些情况下，一些用户会直接把整个url地址写进 baseUrl
    // 因此，还需要对baseUrl 进行一次切割
    NSURL *theUrl = [NSURL URLWithString:baseURL];
    NSURL *root   = [NSURL URLWithString:@"/" relativeToURL:theUrl];
    return [NSString stringWithFormat:@"%@", root.absoluteString];
}

/**
 从API中获取requestURL
 
 @param task 调用的API
 
 @return requestURL
 */
- (NSString *)requestURLStringWithTask:(HLTask *)task {
    NSParameterAssert(task);
    if (task.taskURL) {
        return task.taskURL;
    }
    NSAssert(task.baseURL != nil || self.config.baseURL != nil,
             @"api baseURL 和 self.config.baseurl 两者必须有一个有值");
    
    // 如果啥都没定义，则使用BaseUrl + requestMethod 组成 UrlString
    // 即，直接返回requestMethod
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", task.baseURL ? : self.config.baseURL, task.path ? : @""]];
    return requestURL.absoluteString;
}

//获取已下载的文件大小
- (unsigned long long)fileSizeForPath:(NSString *)path {
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

/**
 API完成的回调方法
 
 @param task   调用的API
 @param obj   返回的对象
 @param error 返回的错误
 */
- (void)callTaskCompletion:(HLTask *)task obj:(id)obj error:(NSError *)error completion:(void (^)())completion {
    if (self.responseDelegate) {
        if ([[self.responseDelegate requestTasks] containsObject:task]) {
            if (error) {
                if ([self.responseDelegate respondsToSelector:@selector(requestFailureWithResponseError:atTask:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.responseDelegate requestFailureWithResponseError:error atTask:task];
                    });
                }
            } else {
                if ([self.responseDelegate respondsToSelector:@selector(requestSucessWithResponseObject:atTask:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.responseDelegate requestSucessWithResponseObject:obj atTask:task];
                    });
                }
            }
        }
    }
}

/**
 API成功的方法
 
 @param responseObject 返回的对象
 @param task            调用的API
 */
- (void)handleSuccWithResponse:(id)responseObject andTask:(HLTask *)task completion:(void (^)())completion {
    [self callTaskCompletion:task obj:responseObject error:nil completion:completion];
}

/**
 API失败的方法
 
 @param error 返回的错误
 @param task   调用的API
 */
- (void)handleFailureWithError:(NSError *)error andTask:(HLTask *)task completion:(void (^)())completion  {
    
    // Error -999, representing API Cancelled
    if ([error.domain isEqualToString: NSURLErrorDomain] &&
        error.code == NSURLErrorCancelled) {
        [self callTaskCompletion:task obj:nil error:error completion:completion];
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
    
    [self callTaskCompletion:task obj:nil error:err completion:nil];
}

/**
 发送单个Task
 
 @param task 需要发送的API
 */
- (void)sendTaskRequest:(nonnull HLTask *)task {
    NSParameterAssert(task);
    NSAssert(self.config, @"Config不能为空");
    
    dispatch_async(qkhl_task_session_creation_queue(), ^{
        AFURLSessionManager *sessionManager = [self sessionManagerWithTask:task];
        if (!sessionManager) {
            return;
        }
        [self _sendSingleTaskRequest:task withSessionManager:sessionManager andCompletionGroup:nil completionBlock:nil];
    });
}

- (void)_sendSingleTaskRequest:(HLTask *)task
           withSessionManager:(AFURLSessionManager *)sessionManager
           andCompletionGroup:(dispatch_group_t)completionGroup
              completionBlock:(void (^)())completion {
    NSParameterAssert(task);
    NSParameterAssert(sessionManager);
    
    __weak typeof(self) weakSelf = self;
    NSString *host = [self requestBaseURLStringWithTask:task];
    NSString *requestURLStr = [self requestURLStringWithTask:task];
    NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)[task hash]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURLStr]];
    __block NSURL *fileURL = task.filePath ? [NSURL fileURLWithPath:task.filePath] : nil;
    
    // 如果缓存中已有当前task，则立即使api返回失败回调，错误信息为frequentRequestErrorStr，如果是apiBatch，则整组移除
    if ([self.sessionTasksCache objectForKey:hashKey]) {
        NSString *errorStr     = self.config.frequentRequestErrorStr;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr
                                   };
        NSError *cancelError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorCancelled
                                               userInfo:userInfo];
        [self callTaskCompletion:task obj:nil error:cancelError completion:completion];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
        completion();
        return;
    }
    
    // 设置reachbility,监听url为baseURL
    SCNetworkReachabilityRef hostReachable = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
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
                                   NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@ 无法访问", host]
                                   };
        NSError *networkUnreachableError = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:NSURLErrorCannotConnectToHost
                                                           userInfo:userInfo];
        [self callTaskCompletion:task obj:nil error:networkUnreachableError completion:completion];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
        return;
    }
    
    /**
     进度Block
     */
    void (^progressBlock)(NSProgress *progress)
    = self.responseDelegate ? ^(NSProgress *progress) {
        if (progress.totalUnitCount <= 0) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.responseDelegate respondsToSelector:@selector(requestProgress:atTask:)]) {
                [self.responseDelegate requestProgress:progress atTask:task];
            }
        });
    } : nil;
    
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
    
    void (^donwloadCompleteBlcok)(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error)
    = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        if (strongSelf.config.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        if (error) {
            [self handleFailureWithError:error andTask:task completion:completion];
        } else {
            [self handleSuccWithResponse:filePath andTask:task completion:completion];
        }
        [strongSelf.sessionTasksCache removeObjectForKey:hashKey];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
    };
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([task respondsToSelector:@selector(requestWillBeSent)]) {
        if ([[NSThread currentThread] isMainThread]) {
            [task performSelector:@selector(requestWillBeSent)];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [task performSelector:@selector(requestWillBeSent)];
            });
        }
    }
#pragma clang diagnostic pop
    
    if (self.config.isNetworkingActivityIndicatorEnabled) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    NSURLSessionTask *dataTask;
    
    switch (task.requestTaskType) {
        case Upload: {
            dataTask = [sessionManager uploadTaskWithRequest:request
                                                    fromFile:fileURL
                                                    progress:progressBlock
                                           completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                               __strong typeof (weakSelf) strongSelf = weakSelf;
                                               if (strongSelf.config.isNetworkingActivityIndicatorEnabled) {
                                                   [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                               }
                                               if (error) {
                                                   [self handleFailureWithError:error andTask:task completion:completion];
                                               } else {
                                                   [self handleSuccWithResponse:responseObject andTask:task completion:completion];
                                               }
                                               [strongSelf.sessionTasksCache removeObjectForKey:hashKey];
                                               if (completionGroup) {
                                                   dispatch_group_leave(completionGroup);
                                               }
                                           }];
        }
            break;
        case Download: {
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:task.resumePath]];
            if (data) {
                dataTask = [sessionManager downloadTaskWithResumeData:data
                                                             progress:progressBlock
                                                          destination:destinationBlock
                                                    completionHandler:donwloadCompleteBlcok];
            } else {
                dataTask = [sessionManager downloadTaskWithRequest:request
                                                          progress:progressBlock
                                                       destination:destinationBlock
                                                 completionHandler:donwloadCompleteBlcok];
            }
            break;
        }
        default: break;
    }
    
    if (dataTask) {
        [dataTask resume];
        [self.sessionTasksCache setObject:dataTask forKey:hashKey];
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([task respondsToSelector:@selector(requestDidSent)]) {
        if ([[NSThread currentThread] isMainThread]) {
            [task performSelector:@selector(requestDidSent)];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [task performSelector:@selector(requestDidSent)];
            });
        }
    }
#pragma clang diagnostic pop
}

- (void)cancelTaskRequest:(HLTask *)task {
    dispatch_async(qkhl_task_session_creation_queue(), ^{
        NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)[task hash]];
        if (task.requestTaskType == Download) {
            NSURLSessionDownloadTask *downloadTask = [self.sessionTasksCache objectForKey:hashKey];
            if (downloadTask) {
                [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    [resumeData writeToFile:task.resumePath atomically:YES];
                }];
            }
        } else {
            NSURLSessionUploadTask *task = [self.sessionTasksCache objectForKey:hashKey];
            [self.sessionTasksCache removeObjectForKey:hashKey];
            if (task) {
                [task cancel];
            }
        }
    });
}

- (void)resumeTaskRequest:(HLTask *)task {
    dispatch_async(qkhl_task_session_creation_queue(), ^{
        NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)[task hash]];
        if (task.requestTaskType == Download) {
            NSURLSessionDownloadTask *downloadTask = [self.sessionTasksCache objectForKey:hashKey];
            if (downloadTask) {
                [downloadTask resume];
            } else {
                [self sendTaskRequest:task];
            }
        } else {
            NSURLSessionUploadTask *uploadTask = [self.sessionTasksCache objectForKey:hashKey];
            if (uploadTask) {
                [uploadTask resume];
            } else {
                [self.sessionTasksCache setObject:uploadTask forKey:hashKey];
                [uploadTask resume];
            }
        }
    });
}

- (void)pauseTaskRequest:(HLTask *)task {
    dispatch_async(qkhl_task_session_creation_queue(), ^{
        NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)[task hash]];
        if (task.requestTaskType == Download) {
            NSURLSessionDownloadTask *downloadTask = [self.sessionTasksCache objectForKey:hashKey];
            if (downloadTask) {
                [downloadTask suspend];
            }
        } else {
            NSURLSessionUploadTask *uploadTask = [self.sessionTasksCache objectForKey:hashKey];
            if (uploadTask) {
                [uploadTask suspend];
            }
        }
    });
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
