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
#import "HLNetworkMacro.h"
#import "HLNetworkEngine.h"
#import "HLSecurityPolicyConfig.h"

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
    }
    return self;
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
        if (task.retryCount > 0) {
            task.retryCount --;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self send:task atSemaphore:semaphore atGroup:group];
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
    
    // 设置Debug及log信息
    HLDebugMessage *msg = [[HLDebugMessage alloc] initWithRequest:task
                                                        andResult:resultObject
                                                         andError:netError
                                                     andQueueName:[NSString stringWithFormat:@"%@", self.currentQueue]];
#if DEBUG
    if (self.config.enableGlobalLog) {
        [HLNetworkLogger logInfoWithDebugMessage:msg];
    }
#endif
    if ([HLNetworkLogger isEnable]) {
        NSDictionary *msgDictionary;
        if ([[HLNetworkLogger currentDelegate] respondsToSelector:@selector(customInfoWithMessage:)]) {
            msgDictionary = [[HLNetworkLogger currentDelegate] customInfoWithMessage:msg];
        } else {
            msgDictionary = [msg toDictionary];
        }
        [HLNetworkLogger addLogInfoWithDictionary:msgDictionary];
    }
    
    if (netError) {
        if ([task taskFailureHandler]) {
            dispatch_async_main(^{
                task.taskFailureHandler(netError);
                task.taskFailureHandler = nil;
            });
        }
    } else {
        if ([task taskSuccessHandler]) {
            dispatch_async_main(^{
                task.taskSuccessHandler(resultObject);
                task.taskSuccessHandler = nil;
            });
        }
    }
    
    for (id<HLTaskResponseProtocol> delegate in self.responseObservers) {
        if ([[delegate requestTasks] containsObject:task]) {
            if (netError) {
                if ([delegate respondsToSelector:@selector(requestFailureWithResponseError:atTask:)]) {
                    dispatch_async_main(^{
                        [delegate requestFailureWithResponseError:netError atTask:task];
                    });
                }
            } else {
                if ([delegate respondsToSelector:@selector(requestSucessWithResponseObject:atTask:)]) {
                    dispatch_async_main(^{
                        [delegate requestSucessWithResponseObject:resultObject atTask:task];
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

- (void)send:(HLTask *)task
 atSemaphore:(dispatch_semaphore_t)semaphore
     atGroup:(dispatch_group_t)group {
    // 对task.delegate 发送即将请求task的消息
    if ([task.delegate respondsToSelector:@selector(requestWillBeSentWithTask:)]) {
        dispatch_async_main(^{
            [task.delegate requestWillBeSentWithTask:task];
        });
    }
    
    if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    
    @hl_weakify(self)
    [[HLNetworkEngine sharedEngine] sendRequest:task andConfig:self.config progressBack:^(NSProgress * _Nullable progress) {
        if (progress.totalUnitCount <= 0) return;
        dispatch_async_main(^{
            for (id<HLTaskResponseProtocol> obj in self.responseObservers) {
                if ([[obj requestTasks] containsObject:task]) {
                    if ([obj respondsToSelector:@selector(requestProgress:atTask:)]) {
                        [obj requestProgress:progress atTask:task];
                    }
                }
            }
        });
    } callBack:^(id  _Nonnull request, id  _Nullable responseObject, NSError * _Nullable error) {
        @hl_strongify(self)
        if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        [self callbackWithRequest:task andResultObject:responseObject andError:error andGroup:group andSemaphore:semaphore];
    }];
    
    // 对task.delegate 发送已经请求task的消息
    if ([task.delegate respondsToSelector:@selector(requestDidSentWithTask:)]) {
        dispatch_async_main(^{
            [task.delegate requestDidSentWithTask:task];
        });
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
        [self send:task atSemaphore:nil atGroup:nil];
    });
}

- (void)cancel:(HLTask *)task {
    if (!task.queue) {
        task.queue = self.currentQueue;
    }
    dispatch_async(task.queue, ^{
        task.taskSuccessHandler = nil;
        task.taskFailureHandler = nil;
        task.taskProgressHandler = nil;
        [[HLNetworkEngine sharedEngine] cancelRequestByIdentifier:task.hashKey];
    });
}

- (void)resume:(HLTask *)task {
    @hl_weakify(self);
    if (!task.queue) {
        task.queue = self.currentQueue;
    }
    dispatch_async(task.queue, ^{
        @hl_strongify(self);
        NSURLSessionTask *sessionTask = [[HLNetworkEngine sharedEngine] requestByIdentifier:task.hashKey];
        if (![sessionTask isKindOfClass:[NSNull class]]) {
            [sessionTask resume];
        } else {
            [self send:task];
        }
    });
}

- (void)pause:(HLTask *)task {
    if (!task.queue) {
        task.queue = self.currentQueue;
    }
    dispatch_async(task.queue, ^{
        NSURLSessionTask *sessionTask = [[HLNetworkEngine sharedEngine] requestByIdentifier:task.hashKey];
        if (![sessionTask isKindOfClass:[NSNull class]]) {
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
            [self send:task atSemaphore:semaphore atGroup:task_group];
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
