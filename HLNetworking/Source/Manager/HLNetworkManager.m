//
//  HLNetworkManager.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLNetworkManager.h"
#import "HLNetworkEngine.h"
#import "HLNetworkConfig.h"
#import "HLNetworkMacro.h"
#import "HLNetworkLogger.h"
#import "HLDebugMessage.h"
#import "HLURLRequest_InternalParams.h"
#import "HLRequestGroup.h"
#import "HLTaskRequest.h"
#import "HLAPIRequest_InternalParams.h"

inline BOOL HLJudgeVersion(void) { return [[NSUserDefaults standardUserDefaults] boolForKey:@"isR"]; }

inline void HLJudgeVersionSwitch(BOOL isR) { [[NSUserDefaults standardUserDefaults] setBool:isR forKey:@"isR"]; }

// 创建任务队列
static dispatch_queue_t qkhl_network_creation_queue() {
    static dispatch_queue_t qkhl_network_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        qkhl_network_creation_queue =
        dispatch_queue_create("com.qkhl.wangshiyu13.networking.callback.queue", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    });
    return qkhl_network_creation_queue;
}

// 创建上传下载任务队列
static dispatch_queue_t qkhl_network_task_queue() {
    static dispatch_queue_t qkhl_network_task_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        qkhl_network_task_queue =
        dispatch_queue_create("com.qkhl.wangshiyu13.networking.task.queue", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    });
    return qkhl_network_task_queue;
}

static NSLock* managerLock = nil;

@interface HLNetworkManager ()
@property (nonatomic, strong, readwrite) HLNetworkConfig *config;
@property (nonatomic, strong) NSHashTable<id <HLNetworkResponseDelegate>> *responseObservers;

@property (nonatomic, assign, readwrite) HLReachabilityStatus reachabilityStatus;
@property (nonatomic, assign, readwrite, getter = isReachable) BOOL reachable;
@property (nonatomic, assign, readwrite, getter = isReachableViaWWAN) BOOL reachableViaWWAN;
@property (nonatomic, assign, readwrite, getter = isReachableViaWiFi) BOOL reachableViaWiFi;
@property (nonatomic, strong) dispatch_queue_t currentRequestQueue;
@property (nonatomic, strong) dispatch_queue_t currentTaskQueue;
@end

@implementation HLNetworkManager
+ (HLNetworkConfig *)config {
    return [[self sharedManager] config];
}
#pragma mark - initialize method
+ (instancetype)manager {
    return [[self alloc] init];
}
+ (instancetype)sharedManager {
    static HLNetworkManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            managerLock = [[NSLock alloc] init];
            managerLock.name = @"com.qkhl.wangshiyu13.networking.manager.lock";
        });
        _config = [HLNetworkConfig config];
        _currentRequestQueue = _config.request.apiCallbackQueue ?: qkhl_network_creation_queue();
        _currentTaskQueue = qkhl_network_task_queue();
        _reachabilityStatus = HLReachabilityStatusUnknown;
        _responseObservers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    }
    return self;
}
- (void)setupConfig:(void (^)(HLNetworkConfig * _Nonnull config))configBlock {
    HL_SAFE_BLOCK(configBlock, self.config);
    self.currentRequestQueue = self.config.request.apiCallbackQueue ?: qkhl_network_creation_queue();
}
+ (void)setupConfig:(void (^)(HLNetworkConfig * _Nonnull config))configBlock {
    [[self sharedManager] setupConfig:configBlock];
}

#pragma mark - process
// 发送API请求，默认为manager内置队列
- (void)send:(__kindof HLURLRequest *)request {
    @hl_weakify(self);
    if (!request.queue) {
        if ([request isKindOfClass:[HLTaskRequest class]]) {
            request.queue = self.currentTaskQueue;
        } else {
            request.queue = self.currentRequestQueue;
        }
    }
    dispatch_async(request.queue, ^{
        @hl_strongify(self);
        [self send:request atSemaphore:nil atGroup:nil];
    });
}
+ (void)send:(__kindof HLURLRequest *)request {
    [[self sharedManager] send:request];
}
// 发送一组请求，使用信号量做同步请求，使用group做完成通知
- (void)sendGroup:(HLRequestGroup *)group {
    if (!group) return;
    dispatch_queue_t queue;
    if (group.customQueue) {
        queue = group.customQueue;
    } else {
        if ([group[0] isKindOfClass:[HLTaskRequest class]]) {
            queue = self.currentTaskQueue;
        } else {
            queue = self.currentRequestQueue;
        }
    }
    // 根据groupMode 配置信号量
    dispatch_semaphore_t semaphore = nil;
    if (group.groupMode == HLRequestGroupModeChian) {
        semaphore = dispatch_semaphore_create(group.maxRequestCount);
    }
    dispatch_group_t api_group = dispatch_group_create();
    @hl_weakify(self);
    dispatch_async(queue, ^{
        [group enumerateObjectsUsingBlock:^(HLURLRequest * _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop) {
            @hl_strongify(self);
            request.queue = queue;
            if (group.groupMode == HLRequestGroupModeChian) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
            dispatch_group_enter(api_group);
            [self send:request atSemaphore:semaphore atGroup:api_group];
        }];
        dispatch_group_notify(api_group, dispatch_get_main_queue(), ^{
            if (group.delegate) {
                [group.delegate requestGroupAllDidFinished:group];
            }
        });
    });
}
+ (void)sendGroup:(HLRequestGroup *)group {
    [[self sharedManager] sendGroup:group];
}
// 取消API请求，如果该请求已经发送或者正在发送，则不保证一定可以取消，但会将Block回落点置空，delegate正常回调，默认为manager内置队列
- (void)cancel:(__kindof HLURLRequest *)request {
    if (!request.queue) {
        if ([request isKindOfClass:[HLTaskRequest class]]) {
            request.queue = self.currentTaskQueue;
        } else {
            request.queue = self.currentRequestQueue;
        }
    }
    dispatch_async(request.queue, ^{
        [[HLNetworkEngine sharedEngine] cancelRequestByIdentifier:request.hashKey];
    });
}
+ (void)cancel:(__kindof HLURLRequest *)request {
    [[self sharedManager] cancel:request];
}
// 取消API请求，如果该请求已经发送或者正在发送，则不保证一定可以取消，但会将Block回落点置空，delegate正常回调，默认为manager内置队列
- (void)cancelGroup:(HLRequestGroup *)group {
    NSAssert(group.count != 0, @"APIGroup元素不可小于1");
    [group enumerateObjectsUsingBlock:^(__kindof HLURLRequest * _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop) {
        [self cancel:request];
    }];
}
+ (void)cancelGroup:(HLRequestGroup *)group {
    [[self sharedManager] cancelGroup:group];
}
// 恢复Task
- (void)resume:(__kindof HLURLRequest *)request {
    @hl_weakify(self);
    if (!request.queue) {
        if ([request isKindOfClass:[HLTaskRequest class]]) {
            request.queue = self.currentTaskQueue;
        } else {
            request.queue = self.currentRequestQueue;
        }
    }
    dispatch_async(request.queue, ^{
        @hl_strongify(self);
        NSURLSessionTask *sessionTask = [[HLNetworkEngine sharedEngine] requestByIdentifier:request.hashKey];
        if (sessionTask) {
            [sessionTask resume];
        } else {
            [self send:request];
        }
    });
}
+ (void)resume:(__kindof HLURLRequest *)request {
    [[self sharedManager] resume:request];
}
// 暂停Task
- (void)pause:(__kindof HLURLRequest *)request {
    if (!request.queue) {
        if ([request isKindOfClass:[HLTaskRequest class]]) {
            request.queue = self.currentTaskQueue;
        } else {
            request.queue = self.currentRequestQueue;
        }
    }
    dispatch_async(request.queue, ^{
        NSURLSessionTask *sessionTask = [[HLNetworkEngine sharedEngine] requestByIdentifier:request.hashKey];
        if (sessionTask) {
            [sessionTask suspend];
        }
    });
}
+ (void)pause:(__kindof HLURLRequest *)request {
    [[self sharedManager] pause:request];
}
// 注册网络请求监听者
- (void)registerResponseObserver:(id<HLNetworkResponseDelegate>)observer {
    [managerLock lock];
    [self.responseObservers addObject:observer];
    [managerLock unlock];
}
+ (void)registerResponseObserver:(id<HLNetworkResponseDelegate>)observer {
    [[self sharedManager] registerResponseObserver:observer];
}
// 删除网络请求监听者
- (void)removeResponseObserver:(id<HLNetworkResponseDelegate>)observer {
    [managerLock lock];
    if ([self.responseObservers containsObject:observer]) {
        [self.responseObservers removeObject:observer];
    }
    [managerLock unlock];
}
+ (void)removeResponseObserver:(id<HLNetworkResponseDelegate>)observer {
    [[self sharedManager] removeResponseObserver:observer];
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
    return [[self sharedManager] reachabilityStatus];
}

+ (BOOL)isReachable {
    return [[self sharedManager] isReachable];
}

+ (BOOL)isReachableViaWWAN {
    return [[self sharedManager] isReachableViaWWAN];
}

+ (BOOL)isReachableViaWiFi {
    return [[self sharedManager] isReachableViaWiFi];
}

+ (void)listening:(HLReachabilityBlock)listener {
    [[self sharedManager] listeningWithDomain:[[self sharedManager] config].request.baseURL listeningBlock:listener];
}

+ (void)stopListening {
    [[self sharedManager] stopListeningWithDomain:[[self sharedManager] config].request.baseURL];
}

- (void)listeningWithDomain:(NSString *)domain listeningBlock:(HLReachabilityBlock)listener {
    if (self.config.enableReachability) {
        @hl_weakify(self)
        [[HLNetworkEngine sharedEngine] listeningWithDomain:domain listeningBlock:^(HLReachabilityStatus status) {
            @hl_strongify(self)
            self.reachabilityStatus = status;
            listener(status);
        }];
    }
}

- (void)stopListeningWithDomain:(NSString *)domain {
    [[HLNetworkEngine sharedEngine] stopListeningWithDomain:domain];
}

#pragma mark - private method
- (void)send:(HLURLRequest *)request
 atSemaphore:(dispatch_semaphore_t)semaphore
     atGroup:(dispatch_group_t)group {
    // 对api.delegate 发送即将请求api的消息
    if ([request.delegate respondsToSelector:@selector(requestWillBeSent:)]) {
        dispatch_async_main(^{
            [request.delegate requestWillBeSent:request];
        });
    }
    
    if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    
    // 定义进度block
    @hl_weakify(self)
    void (^progressBlock)(NSProgress *proc) = ^(NSProgress *proc) {
        if (proc.totalUnitCount <= 0) return;
        dispatch_async_main(^{
            for (id<HLNetworkResponseDelegate> obj in self.responseObservers) {
                if ([[obj observerRequests] containsObject:request]) {
                    if ([obj respondsToSelector:@selector(requestProgress:atRequest:)]) {
                        [obj requestProgress:proc atRequest:request];
                    }
                }
            }
        });
    };
    // 定义回调block
    void (^callBackBlock)(HLURLRequest *request, id responseObject, NSError *error)
    = ^(HLURLRequest *request, id responseObject, NSError *error) {
        @hl_strongify(self)
        if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        [self callbackWithRequest:request
                  andResultObject:responseObject
                         andError:error
                         andGroup:group
                     andSemaphore:semaphore];
    };
    
    [[HLNetworkEngine sharedEngine] sendRequest:request
                                      andConfig:self.config
                                   progressBack:progressBlock
                                       callBack:callBackBlock];
    
    // 对api.delegate 发送已经请求api的消息
    if ([request.delegate respondsToSelector:@selector(requestDidSent:)]) {
        dispatch_async_main(^{
            [request.delegate requestDidSent:request];
        });
    }
}

/**
 Task完成的回调方法
 
 @param request 调用的request
 @param resultObject 返回的对象
 @param error 返回的错误
 @param group 调用的组
 @param semaphore 调用的信号量
 */
- (void)callbackWithRequest:(HLURLRequest *)request
            andResultObject:(id)resultObject
                   andError:(NSError *)error
                   andGroup:(dispatch_group_t)group
               andSemaphore:(dispatch_semaphore_t)semaphore {
    // 处理回调的block
    NSError *netError = error;
    if (netError) {
        // 网络状态不好时自动重试
        if (request.retryCount > 0) {
            request.retryCount --;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self send:request atSemaphore:semaphore atGroup:group];
            });
            return;
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
    
    if ([request isKindOfClass:[HLAPIRequest class]]) {
        HLAPIRequest *tmpRequest = (HLAPIRequest *)request;
        if (tmpRequest.objReformerDelegate) {
            resultObject = [tmpRequest.objReformerDelegate reformerObject:resultObject andError:netError atRequest:tmpRequest];
        }
    }
    
    // 设置Debug及log信息
    HLDebugMessage *msg = [[HLDebugMessage alloc] initWithRequest:request
                                                        andResult:resultObject
                                                         andError:netError
                                                     andQueueName:[NSString stringWithFormat:@"%@", [request isKindOfClass:[HLTaskRequest class]] ? self.currentTaskQueue : self.currentRequestQueue]];
#if DEBUG
    if (self.config.enableGlobalLog) {
        [HLNetworkLogger logInfoWithDebugMessage:msg];
    }
    if (request.debugHandler) {
        request.debugHandler(msg);
        request.debugHandler = nil;
    }
#endif
    if ([HLNetworkLogger isEnable]) {
        NSDictionary *msgDictionary;
        if ([HLNetworkLogger currentDelegate]) {
            msgDictionary = [[HLNetworkLogger currentDelegate] customInfoWithMessage:msg];
        } else {
            msgDictionary = [msg toDictionary];
        }
        [HLNetworkLogger addLogInfoWithDictionary:msgDictionary];
    }
    
    if (netError) {
        if ([request failureHandler]) {
            dispatch_async_main(^{
                request.failureHandler(netError);
                request.failureHandler = nil;
            });
        }
    } else {
        if ([request successHandler]) {
            dispatch_async_main(^{
                request.successHandler(resultObject);
                request.successHandler = nil;
            });
        }
    }
    
    if (request.progressHandler) {
        request.progressHandler = nil;
    }
    
    // 处理回调的delegate
    for (id<HLNetworkResponseDelegate> observer in self.responseObservers) {
        if ([[observer observerRequests] containsObject:request]) {
            if (netError) {
                if ([observer respondsToSelector:@selector(requestFailure:atRequest:)]) {
                    dispatch_async_main(^{
                        [observer requestFailure:netError atRequest:request];
                    });
                }
            } else {
                if ([observer respondsToSelector:@selector(requestSucess:atRequest:)]) {
                    dispatch_async_main(^{
                        [observer requestSucess:resultObject atRequest:request];
                    });
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
@end
