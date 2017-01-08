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
#import "HLTask_InternalParams.h"
#import "HLTaskGroup.h"
#import "HLDebugMessage.h"
#import "HLNetworkLogger.h"
#import "HLNetworkConfig.h"
#import "HLSecurityPolicyConfig.h"
#import "HLNetworkMacro.h"
#import <AFNetworking/AFURLSessionManager.h>

// 创建任务队列
static dispatch_queue_t qkhl_task_session_creation_queue() {
    static dispatch_queue_t qkhl_task_session_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        qkhl_task_session_creation_queue =
        dispatch_queue_create("com.qkhl.pp.networking.wangshiyu13.task.callback.queue", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    });
    return qkhl_task_session_creation_queue;
}

@interface HLTaskManager ()
@property (nonatomic, strong, readwrite) HLNetworkConfig *config;
@property (nonatomic, strong) NSMutableDictionary <NSString *, AFURLSessionManager *>*sessionManagerCache;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSURLSessionTask *>*sessionTaskCache;
@property (nonatomic, strong) NSHashTable<id <HLTaskResponseProtocol>> *responseObservers;

@property (nonatomic, strong) dispatch_queue_t currentQueue;
@end

@implementation HLTaskManager
#pragma mark - SetupConfig
- (void)setupConfig:(void (^)(HLNetworkConfig * _Nonnull config))configBlock {
    HL_SAFE_BLOCK(configBlock, self.config);
}

+ (void)setupConfig:(void (^)(HLNetworkConfig * _Nonnull config))configBlock {
    return [[self sharedManager] setupConfig:configBlock];
}

#pragma mark - init method
+ (instancetype)manager {
    return [[self alloc] init];
}

+ (HLTaskManager *)sharedManager {
    static HLTaskManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [HLNetworkConfig config];
        _currentQueue = _config.request.taskCallbackQueue ?: qkhl_task_session_creation_queue();
        _responseObservers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
        _sessionManagerCache = [NSMutableDictionary dictionary];
        _sessionTaskCache = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - AFURLSessionManager
/**
 根据API的BaseURL创建AFSessionManager
 
 @param task 调用的API
 
 @return AFHTTPSessionManager
 */
- (AFURLSessionManager *)sessionManagerWithTask:(HLTask *)task {
    if (!task) {
        return nil;
    }
    
    // 拼接baseUrlStr
    NSString *baseUrlStr;
    // 如果定义了自定义的cURL, 则直接使用
    NSURL *taskURL = [NSURL URLWithString:task.taskURL];
    if (taskURL) {
        baseUrlStr = [NSString stringWithFormat:@"%@://%@", taskURL.scheme, taskURL.host];
    } else {
        NSAssert(task.baseURL != nil || self.config.request.baseURL != nil,
                 @"task baseURL 和 self.config.baseurl 两者必须有一个有值");
        
        NSString *tmpStr = task.baseURL ? : self.config.request.baseURL;
        
        // 在某些情况下，一些用户会直接把整个url地址写进 baseUrl
        // 因此，还需要对baseUrl 进行一次切割
        NSURL *tmpURL = [NSURL URLWithString:tmpStr];
        baseUrlStr = [NSString stringWithFormat:@"%@://%@", tmpURL.scheme, tmpURL.host];;
    }
    
    // 设置session的安全策略
    NSUInteger pinningMode                  = task.securityPolicy.SSLPinningMode;
    AFSecurityPolicy *securityPolicy        = [AFSecurityPolicy policyWithPinningMode:pinningMode];
    securityPolicy.allowInvalidCertificates = task.securityPolicy.allowInvalidCertificates;
    securityPolicy.validatesDomainName      = task.securityPolicy.validatesDomainName;
    NSString *cerPath                       = task.securityPolicy.cerFilePath;
    NSData *certData = nil;
    if (cerPath && ![cerPath isEqualToString:@""]) {
        certData = [NSData dataWithContentsOfFile:cerPath];
        if (certData) {
            securityPolicy.pinnedCertificates = [NSSet setWithObject:certData];
        }
    }
    
    // AFURLSessionManager
    AFURLSessionManager *sessionManager;
    sessionManager = [self.sessionManagerCache objectForKey:baseUrlStr];
    // 如果缓存中取不到对应的sessionManager，则创建一个新的SessionManager
    if (!sessionManager) {
        NSURLSessionConfiguration *sessionConfig;
        if (self.config) {
            if (self.config.policy.isBackgroundSession) {
                NSString *kBackgroundSessionID = [NSString stringWithFormat:@"com.wangshiyu13.backgroundSession.task.%@", baseUrlStr];
                NSString *kSharedContainerIdentifier = self.config.policy.AppGroup ?: [NSString stringWithFormat:@"com.wangshiyu13.testApp"];
                sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionID];
                sessionConfig.sharedContainerIdentifier = kSharedContainerIdentifier;
            } else {
                sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            }
            sessionConfig.HTTPMaximumConnectionsPerHost = self.config.request.maxHttpConnectionPerHost;
        } else {
            sessionConfig.HTTPMaximumConnectionsPerHost = MAX_HTTP_CONNECTION_PER_HOST;
        }
        sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfig];
        [self.sessionManagerCache setObject:sessionManager forKey:baseUrlStr];
    }
    sessionManager.securityPolicy = securityPolicy;
    return sessionManager;
}

#pragma mark - Response Complete Handler
/**
 Task完成的回调方法

 @param task 调用的Task
 @param resultObject 返回的对象
 @param error 返回的错误
 @param group 调用的组
 @param semaphore 调用的信号量
 */
- (void)callbackWithRequest:(HLTask *)task
            andResultObject:(id)resultObject
                   andError:(NSError *)error
                   andGroup:(dispatch_group_t)group
               andSemaphore:(dispatch_semaphore_t)semaphore {
    // 处理回调的block
    NSError *netError = error;
    if (netError) {
        // 网络状态不好时自动重试
        if (error.code == NSURLErrorCannotConnectToHost) {
            if (task.retryCount > 0) {
                task.retryCount --;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), task.queue, ^{
                    [self sendRequest:task withSemaphore:semaphore atGroup:group];
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
    
    // 设置Debug及log信息
    HLDebugMessage *msg = [self debugMessageWithTask:task andResultObject:resultObject andError:netError];
#if DEBUG
    if (self.config.enableGlobalLog) {
        [HLNetworkLogger logInfoWithDebugMessage:msg];
    }
#endif
    if ([HLNetworkLogger isEnable]) {
        NSDictionary *msgDictionary;
        if ([HLNetworkLogger shared].delegate) {
            msgDictionary = [[HLNetworkLogger shared].delegate customInfoWithMessage:msg];
        } else {
            msgDictionary = [msg toDictionary];
        }
        [HLNetworkLogger addLogInfoWithDictionary:msgDictionary];
    }
    
    for (id<HLTaskResponseProtocol> delegate in self.responseObservers) {
        if ([[delegate requestTasks] containsObject:task]) {
            if (netError) {
                if ([delegate respondsToSelector:@selector(requestFailureWithResponseError:atTask:)]) {
                    dispatch_async_main([delegate requestFailureWithResponseError:netError atTask:task];)
                }
            } else {
                if ([delegate respondsToSelector:@selector(requestSucessWithResponseObject:atTask:)]) {
                    dispatch_async_main([delegate requestSucessWithResponseObject:resultObject atTask:task];)
                }
            }
        }
    }
    // 完成后离组
    if (group) {
        dispatch_group_leave(group);
    }
    // 完成后信号量加1
    if (semaphore) {
        dispatch_semaphore_signal(semaphore);
    }
    // 移除dataTask缓存
    if ([self.sessionTaskCache objectForKey:task.hashKey]) {
        [self.sessionTaskCache removeObjectForKey:task.hashKey];
    }
}

- (void)sendRequest:(HLTask *)task
      withSemaphore:(dispatch_semaphore_t)semaphore
            atGroup:(dispatch_group_t)group {
    if (!task) return;
    AFURLSessionManager *sessionManager = [self sessionManagerWithTask:task];
    if (!sessionManager) return;
    @hl_weakify(self);
    
    BOOL isDownloadTask = task.requestTaskType == Upload;
    
    NSString *host;
    NSURL *requestURL;
    NSURL *taskURL = [NSURL URLWithString:task.taskURL];
    if (taskURL) {
        host = [NSString stringWithFormat:@"%@://%@", taskURL.scheme, taskURL.host];
        requestURL = taskURL;
    } else {
        // 如果taskURL没定义，则使用BaseUrl + requestMethod 组成 UrlString
        NSString *tmpStr = [NSString stringWithFormat:@"%@/%@", task.baseURL ?: self.config.request.baseURL, task.path ?: @""];
        NSURL *tmpBaseURL = [NSURL URLWithString:tmpStr];
        host = [NSString stringWithFormat:@"%@://%@", tmpBaseURL.scheme, tmpBaseURL.host];
        requestURL = tmpBaseURL;
    }
    NSAssert(requestURL != nil, @"请求的URL有误！");
    
    NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)[task hash]];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    if (!request) {
        return;
    }
    __block NSURL *fileURL = task.filePath ? [NSURL fileURLWithPath:task.filePath] : nil;
    if (!fileURL) {
        return;
    }
    // 如果缓存中已有当前task，则立即使api返回失败回调，错误信息为frequentRequestErrorStr，如果是apiBatch，则整组移除
    if ([self.sessionTaskCache objectForKey:hashKey]) {
        NSString *errorStr     = self.config.tips.frequentRequestErrorStr;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr
                                   };
        NSError *cancelError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorCancelled
                                               userInfo:userInfo];
        [self callbackWithRequest:task andResultObject:nil andError:cancelError andGroup:group andSemaphore:semaphore];
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
        NSString *errorStr     = self.config.tips.networkNotReachableErrorStr;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr,
                                   NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@ 无法访问", host]
                                   };
        NSError *networkUnreachableError = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:NSURLErrorCannotConnectToHost
                                                           userInfo:userInfo];
        [self callbackWithRequest:task andResultObject:nil andError:networkUnreachableError andGroup:group andSemaphore:semaphore];
        return;
    }
    
    /**
     进度Block
     */
    void (^progressBlock)(NSProgress *progress)
    = self.responseObservers.count != 0 ? ^(NSProgress *progress) {
        if (progress.totalUnitCount <= 0) return;
        dispatch_async_main(for (id<HLTaskResponseProtocol> obj in self.responseObservers) {
            if ([obj respondsToSelector:@selector(requestProgress:atTask:)]) {
                [obj requestProgress:progress atTask:task];
            }
        })
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
    
    void (^uploadCompleteBlock)(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error)
    = ^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        @hl_strongify(self);
        if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        [self callbackWithRequest:task andResultObject:responseObject andError:error andGroup:group andSemaphore:semaphore];
        if (!isDownloadTask) {
            [self.sessionTaskCache removeObjectForKey:hashKey];
        }
    };
    
    void (^donwloadCompleteBlcok)(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error)
    = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        @hl_strongify(self);
        if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        [self callbackWithRequest:task andResultObject:filePath andError:error andGroup:group andSemaphore:semaphore];
        if (isDownloadTask) {
            [self.sessionTaskCache removeObjectForKey:hashKey];
        }
    };
    
    if ([task.delegate respondsToSelector:@selector(requestWillBeSentWithTask:)]) {
        dispatch_async_main([task.delegate requestWillBeSentWithTask:task];)
    }
    if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    NSURLSessionTask *dataTask;
    
    switch (task.requestTaskType) {
        case Upload:
            dataTask = [sessionManager uploadTaskWithRequest:request
                                                    fromFile:fileURL
                                                    progress:progressBlock
                                           completionHandler:uploadCompleteBlock];
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
        }
            break;
        default: break;
    }
    
    if (dataTask) {
        [dataTask resume];
        [self.sessionTaskCache setObject:dataTask forKey:hashKey];
    }
    
    if ([task.delegate respondsToSelector:@selector(requestDidSentWithTask:)]) {
        dispatch_async_main([task.delegate requestDidSentWithTask:task];)
    }
}

/**
 发送单个Task
 
 @param task 需要发送的API
 */
- (void)send:(nonnull HLTask *)task {
    @hl_weakify(self);
    if (!task.queue) {
        task.queue = self.currentQueue;
    }
    dispatch_async(task.queue, ^{
        @hl_strongify(self);
        [self sendRequest:task withSemaphore:nil atGroup:nil];
    });
}

- (void)cancel:(HLTask *)task {
    @hl_weakify(self);
    if (!task.queue) {
        task.queue = self.currentQueue;
    }
    dispatch_async(task.queue, ^{
        @hl_strongify(self);
        NSURLSessionTask *sessionTask = [self.sessionTaskCache objectForKey:task.hashKey];
        if (sessionTask) {
            if (task.requestTaskType == Download) {
                [(NSURLSessionDownloadTask *)sessionTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    [resumeData writeToFile:task.resumePath atomically:YES];
                }];
            } else {
                [sessionTask cancel];
            }
            [self.sessionTaskCache removeObjectForKey:task.hashKey];
        }
    });
}

- (void)resume:(HLTask *)task {
    @hl_weakify(self);
    if (!task.queue) {
        task.queue = self.currentQueue;
    }
    dispatch_async(task.queue, ^{
        @hl_strongify(self);
        NSURLSessionTask *sessionTask = [self.sessionTaskCache objectForKey:task.hashKey];
        if (sessionTask) {
            [sessionTask resume];
        } else {
            [self send:task];
        }
    });
}

- (void)pause:(HLTask *)task {
    @hl_weakify(self);
    if (!task.queue) {
        task.queue = self.currentQueue;
    }
    dispatch_async(task.queue, ^{
        @hl_strongify(self);
        NSURLSessionTask *sessionTask = [self.sessionTaskCache objectForKey:task.hashKey];
        if (sessionTask) {
            [sessionTask suspend];
        }
    });
}

- (void)sendGroup:(HLTaskGroup *)taskGroup {
    if (!taskGroup) return;
    dispatch_queue_t queue;
    if (taskGroup.customQueue) {
        queue = taskGroup.customQueue;
    } else {
        queue = self.currentQueue;
    }
    // 根据groupMode 配置信号量
    dispatch_semaphore_t semaphore = nil;
    if (taskGroup.groupMode == HLTaskGroupModeChian) {
        semaphore = dispatch_semaphore_create(taskGroup.maxRequestCount);
    }
    dispatch_group_t task_group = dispatch_group_create();
    @hl_weakify(self);
    dispatch_async(queue, ^{
        [taskGroup enumerateObjectsUsingBlock:^(HLTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            @hl_strongify(self);
            task.queue = queue;
            if (taskGroup.groupMode == HLTaskGroupModeChian) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
            dispatch_group_enter(task_group);
            AFURLSessionManager *sessionManager = [self sessionManagerWithTask:task];
            if (!sessionManager) {
                dispatch_group_leave(task_group);
                *stop = YES;
            }
            sessionManager.completionGroup = task_group;
            [self sendRequest:task withSemaphore:semaphore atGroup:task_group];
        }];
        dispatch_group_notify(task_group, dispatch_get_main_queue(), ^{
            if (taskGroup.delegate) {
                [taskGroup.delegate taskGroupAllDidFinished:taskGroup];
            }
        });
    });
}

- (void)cancelGroup:(HLTaskGroup *)taskGroup {
    NSAssert(taskGroup.count != 0, @"APIGroup元素不可小于1");
    [taskGroup enumerateObjectsUsingBlock:^(HLTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        [self cancel:task];
    }];
}

#pragma mark - Network Response Observer
- (void)registerResponseObserver:(nonnull id<HLTaskResponseProtocol>)observer {
    [self.responseObservers addObject:observer];
}

- (void)removeResponseObserver:(nonnull id<HLTaskResponseProtocol>)observer {
    if ([self.responseObservers containsObject:observer]) {
        [self.responseObservers removeObject:observer];
    }
}

#pragma mark - private method
- (HLDebugMessage *)debugMessageWithTask:(HLTask *)task
                         andResultObject:(id)resultObject
                                andError:(NSError *)error
{
    id sessionTask = [self.sessionTaskCache objectForKey:task.hashKey] ?: [NSNull null];
    // 生成response对象
    HLURLResult *result = [[HLURLResult alloc] initWithObject:resultObject andError:error];
    HLURLResponse *response = [[HLURLResponse alloc] initWithResult:result
                                                          requestId:[NSNumber numberWithUnsignedInteger:[task hash]]
                                                            request:[sessionTask currentRequest]];
    
    NSDictionary *params = @{kHLRequestDebugKey: task,
                             kHLSessionTaskDebugKey: sessionTask,
                             kHLResponseDebugKey: response,
                             kHLQueueDebugKey: self.currentQueue};
    return [[HLDebugMessage alloc] initWithDict:params];
}

#pragma mark - 单例用的静态方法
// 发送Task请求
+ (void)send:(HLTask *)task {
    [[self sharedManager] send:task];
}

// 取消Task，如果该请求已经发送或者正在发送，则不保证一定可以取消
+ (void)cancel:(HLTask *)task {
    [[self sharedManager] cancel:task];
}

// 恢复Task
+ (void)resume:(HLTask *)task {
    [[self sharedManager] resume:task];
}

// 暂停Task
+ (void)pause:(HLTask *)task {
    [[self sharedManager] pause:task];
}

+ (void)sendGroup:(HLTaskGroup *)taskGroup {
    [[self sharedManager] sendGroup:taskGroup];
}

+ (void)cancelGroup:(HLTaskGroup *)taskGroup {
    [[self sharedManager] cancelGroup:taskGroup];
}

// 注册网络请求监听者
+ (void)registerResponseObserver:(id<HLTaskResponseProtocol>)observer {
    [[self sharedManager] registerResponseObserver:observer];
}

// 删除网络请求监听者
+ (void)removeResponseObserver:(id<HLTaskResponseProtocol>)observer {
    [[self sharedManager] removeResponseObserver:observer];
}

#pragma mark - private method
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
@end
