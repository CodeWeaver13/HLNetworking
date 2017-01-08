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
        dispatch_queue_create("com.qkhl.pp.networking.wangshiyu13.task.callback.queue", DISPATCH_QUEUE_SERIAL);
    });
    return qkhl_task_session_creation_queue;
}

@interface HLTaskManager ()
@property (nonatomic, strong, readwrite) HLNetworkConfig *config;
@property (nonatomic, strong) NSMutableDictionary <NSString *, AFURLSessionManager *>*sessionManagerCache;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSURLSessionDownloadTask *>*downloadTasksCache;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSURLSessionUploadTask *>*uploadTasksCache;
@property (nonatomic, strong) NSHashTable<id <HLTaskResponseProtocol>> *responseObservers;
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
        _responseObservers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
        _sessionManagerCache = [NSMutableDictionary dictionary];
        _downloadTasksCache = [NSMutableDictionary dictionary];
        _uploadTasksCache = [NSMutableDictionary dictionary];
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
    NSData *certData                        = [NSData dataWithContentsOfFile:cerPath];
    securityPolicy.pinnedCertificates       = [NSSet setWithObject:certData];
    
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
 API完成的回调方法

 @param task 调用的API
 @param obj 返回的对象
 @param error 返回的错误
 */
- (void)callTaskCompletion:(HLTask *)task obj:(id)obj error:(NSError *)error {
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
    if (self.responseObservers.count > 0) {
        for (id<HLTaskResponseProtocol> delegate in self.responseObservers) {
            if ([[delegate requestTasks] containsObject:task]) {
                if (netError) {
                    if ([delegate respondsToSelector:@selector(requestFailureWithResponseError:atTask:)]) {
                        dispatch_async_main([delegate requestFailureWithResponseError:netError atTask:task];)
                    }
                } else {
                    if ([delegate respondsToSelector:@selector(requestSucessWithResponseObject:atTask:)]) {
                        dispatch_async_main([delegate requestSucessWithResponseObject:obj atTask:task];)
                    }
                }
            }
        }
    }
}

- (void)sendRequest:(HLTask *)task {
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
    if ([self.downloadTasksCache objectForKey:hashKey] || [self.uploadTasksCache objectForKey:hashKey]) {
        NSString *errorStr     = self.config.tips.frequentRequestErrorStr;
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey : errorStr
                                   };
        NSError *cancelError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorCancelled
                                               userInfo:userInfo];
        [self callTaskCompletion:task obj:nil error:cancelError];
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
        [self callTaskCompletion:task obj:nil error:networkUnreachableError];
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
    
    void (^donwloadCompleteBlcok)(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error)
    = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        @hl_strongify(self);
        if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        [self callTaskCompletion:task obj:filePath error:error];
        if (isDownloadTask) {
            [self.downloadTasksCache removeObjectForKey:hashKey];
        }
    };
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([task respondsToSelector:@selector(requestWillBeSent)]) {
        dispatch_async_main([task performSelector:@selector(requestWillBeSent)];)
    }
#pragma clang diagnostic pop
    
    if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    NSURLSessionTask *dataTask;
    
    switch (task.requestTaskType) {
        case Upload: {
            dataTask = [sessionManager uploadTaskWithRequest:request
                                                    fromFile:fileURL
                                                    progress:progressBlock
                                           completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                               @hl_strongify(self);
                                               if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
                                                   [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                               }
                                               [self callTaskCompletion:task obj:responseObject error:error];
                                               if (!isDownloadTask) {
                                                   [self.uploadTasksCache removeObjectForKey:hashKey];
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
        if (isDownloadTask) {
            [self.downloadTasksCache setObject:(NSURLSessionDownloadTask *)dataTask forKey:hashKey];
        } else {
            [self.uploadTasksCache setObject:(NSURLSessionUploadTask *)dataTask forKey:hashKey];
        }
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([task respondsToSelector:@selector(requestDidSent)]) {
        dispatch_async_main([task performSelector:@selector(requestDidSent)];)
    }
#pragma clang diagnostic pop
}

/**
 发送单个Task
 
 @param task 需要发送的API
 */
- (void)send:(nonnull HLTask *)task {
    if (!task) return;
    if (!self.config) return;
    
    dispatch_async(qkhl_task_session_creation_queue(), ^{
        [self sendRequest:task];
    });
}

- (void)cancel:(HLTask *)task {
    dispatch_async(qkhl_task_session_creation_queue(), ^{
        NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)task.hash];
        if (task.requestTaskType == Download) {
            NSURLSessionDownloadTask *downloadTask = [self.downloadTasksCache objectForKey:hashKey];
            if (downloadTask) {
                [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    [resumeData writeToFile:task.resumePath atomically:YES];
                }];
                [self.downloadTasksCache removeObjectForKey:hashKey];
            }
        } else {
            NSURLSessionUploadTask *task = [self.uploadTasksCache objectForKey:hashKey];
            if (task) {
                [task cancel];
                [self.uploadTasksCache removeObjectForKey:hashKey];
            }
        }
    });
}

- (void)resume:(HLTask *)task {
    dispatch_async(qkhl_task_session_creation_queue(), ^{
        NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)task.hash];
        if (task.requestTaskType == Download) {
            NSURLSessionDownloadTask *downloadTask = [self.downloadTasksCache objectForKey:hashKey];
            if (downloadTask) {
                [downloadTask resume];
            } else {
                [self send:task];
            }
        } else {
            NSURLSessionUploadTask *uploadTask = [self.uploadTasksCache objectForKey:hashKey];
            if (uploadTask) {
                [uploadTask resume];
            } else {
                [self send:task];
            }
        }
    });
}

- (void)pause:(HLTask *)task {
    dispatch_async(qkhl_task_session_creation_queue(), ^{
        NSString *hashKey = [NSString stringWithFormat:@"%lu", (unsigned long)[task hash]];
        if (task.requestTaskType == Download) {
            NSURLSessionDownloadTask *downloadTask = [self.downloadTasksCache objectForKey:hashKey];
            if (downloadTask) {
                [downloadTask suspend];
            }
        } else {
            NSURLSessionUploadTask *uploadTask = [self.uploadTasksCache objectForKey:hashKey];
            if (uploadTask) {
                [uploadTask suspend];
            }
        }
    });
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
