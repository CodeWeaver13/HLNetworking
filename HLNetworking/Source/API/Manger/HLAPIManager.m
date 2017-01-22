
//  HLAPIManager.m
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/17.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLAPIManager.h"
#import "HLURLResponse.h"
#import "HLNetworkMacro.h"
#import "HLSecurityPolicyConfig.h"
#import "HLMultipartFormDataProtocol.h"
#import "HLNetworkErrorProtocol.h"
#import "HLNetworkConfig.h"
#import "HLAPI.h"
#import "HLAPI_InternalParams.h"
#import "HLAPIGroup.h"
#import "HLNetworkLogger.h"
#import "HLAPIEngine.h"
#import <SystemConfiguration/SystemConfiguration.h>

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
@property (nonatomic, strong) NSHashTable<id <HLAPIResponseDelegate>> *responseObservers;
@property (nonatomic, strong) NSHashTable<id <HLNetworkErrorProtocol>> *errorObservers;

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

#pragma mark - Response Complete Handler
/**
 API完成的回调方法

 @param api 调用的API
 @param resultObject 请求的返回结果
 @param error 请求返回的错误
 @param semaphore 信号量
 */
- (void)callbackWithRequest:(HLAPI *)api
            andResultObject:(id)resultObject
                   andError:(NSError *)error
                   andGroup:(dispatch_group_t)group
               andSemaphore:(dispatch_semaphore_t)semaphore
{
    // 处理回调的block
    NSError *netError = error;
    if (netError) {
        // 网络状态不好时自动重试
        if (api.retryCount > 0) {
            api.retryCount --;
            if (!api.queue) {
                api.queue = self.currentQueue;
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self send:api atSemaphore:semaphore atGroup:group];
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
    // 处理数据转换
    if ([api objReformerDelegate]) {
        resultObject = [api.objReformerDelegate objReformerWithAPI:api andResponseObject:resultObject andError:netError];
    }
    
    // 设置Debug及log信息
    HLDebugMessage *msg = [self debugMessageWithAPI:api andResultObject:resultObject andError:netError];
#if DEBUG
    if ([api apiDebugHandler]) {
        dispatch_async_main(^{
            api.apiDebugHandler(msg);
            api.apiDebugHandler = nil;
        });
    }
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
        for (id<HLNetworkErrorProtocol> observer in self.errorObservers) {
            dispatch_async_main(^{
                [observer networkErrorInfo:netError];
            });
        }
        if ([api apiFailureHandler]) {
            dispatch_async_main(^{
                api.apiFailureHandler(netError);
                api.apiFailureHandler = nil;
            });
        }
    } else {
        if ([api apiSuccessHandler]) {
            dispatch_async_main(^{
                api.apiSuccessHandler(resultObject);
                api.apiSuccessHandler = nil;
            });
        }
    }
    
    // 处理回调的delegate
    for (id<HLAPIResponseDelegate> observer in self.responseObservers) {
        if ([observer.requestAPIs containsObject:api]) {
            if (netError) {
                if ([observer respondsToSelector:@selector(requestFailureWithResponseError:atAPI:)]) {
                    dispatch_async_main(^{
                        [observer requestFailureWithResponseError:netError atAPI:api];
                    });
                }
            } else {
                if ([observer respondsToSelector:@selector(requestSucessWithResponseObject:atAPI:)]) {
                    dispatch_async_main(^{
                        [observer requestSucessWithResponseObject:resultObject atAPI:api];
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

#pragma mark - Send Request
- (void)send:(HLAPI *)api
 atSemaphore:(dispatch_semaphore_t)semaphore
     atGroup:(dispatch_group_t)group
{
    // 对api.delegate 发送即将请求api的消息
    if ([api.delegate respondsToSelector:@selector(requestWillBeSentWithAPI:)]) {
        dispatch_async_main(^{
            [api.delegate requestWillBeSentWithAPI:api];
        });
    }
    
    if (self.config.tips.isNetworkingActivityIndicatorEnabled) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    
    @hl_weakify(self)
    [[HLAPIEngine sharedEngine] sendRequest:api andConfig:self.config progressBack:^(NSProgress *progress) {
        for (id<HLAPIResponseDelegate> obj in self.responseObservers) {
            if ([obj respondsToSelector:@selector(requestProgress:atAPI:)]) {
                [obj requestProgress:progress atAPI:api];
            }
        }
    } callBack:^(HLAPI *api, id responseObject, NSError *error) {
        @hl_strongify(self)
        [self callbackWithRequest:api andResultObject:responseObject andError:error andGroup:group andSemaphore:semaphore];
    }];
    
    // 对api.delegate 发送已经请求api的消息
    if ([api.delegate respondsToSelector:@selector(requestDidSentWithAPI:)]) {
        dispatch_async_main(^{
            [api.delegate requestDidSentWithAPI:api];
        });
    }
}

/**
 发送单个API
 
 @param api 需要发送的API
 */
- (void)send:(HLAPI *)api {
    @hl_weakify(self);
    if (!api.queue) {
        api.queue = self.currentQueue;
    }
    dispatch_async(api.queue, ^{
        @hl_strongify(self);
        [self send:api atSemaphore:nil atGroup:nil];
    });
}

- (void)cancel:(HLAPI *)api {
    if (!api.queue) {
        api.queue = self.currentQueue;
    }
    dispatch_async(api.queue, ^{
        [[HLAPIEngine sharedEngine] cancelRequest:api];
    });
}

#pragma mark - Send Sync Chain Requests

/**
 使用信号量做同步请求
 
 @param group api组
 */
- (void)sendGroup:(HLAPIGroup *)group {
    if (!group) return;
    dispatch_queue_t queue;
    if (group.customQueue) {
        queue = group.customQueue;
    } else {
        queue = self.currentQueue;
    }
    // 根据groupMode 配置信号量
    dispatch_semaphore_t semaphore = nil;
    if (group.groupMode == HLAPIGroupModeChian) {
        semaphore = dispatch_semaphore_create(group.maxRequestCount);
    }
    dispatch_group_t api_group = dispatch_group_create();
    @hl_weakify(self);
    dispatch_async(queue, ^{
        [group enumerateObjectsUsingBlock:^(HLAPI * _Nonnull api, NSUInteger idx, BOOL * _Nonnull stop) {
            @hl_strongify(self);
            api.queue = queue;
            if (group.groupMode == HLAPIGroupModeChian) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
            dispatch_group_enter(api_group);
            [self send:api atSemaphore:semaphore atGroup:api_group];
        }];
        dispatch_group_notify(api_group, dispatch_get_main_queue(), ^{
            if (group.delegate) {
                [group.delegate apiGroupAllDidFinished:group];
            }
        });
    });
}

- (void)cancelGroup:(HLAPIGroup *)group {
    NSAssert(group.count != 0, @"APIGroup元素不可小于1");
    [group enumerateObjectsUsingBlock:^(HLAPI * _Nonnull api, NSUInteger idx, BOOL * _Nonnull stop) {
        [self cancel:api];
    }];
}

#pragma mark - private method
- (HLDebugMessage *)debugMessageWithAPI:(HLAPI *)api
                        andResultObject:(id)resultObject
                               andError:(NSError *)error
{
    id task = [[HLAPIEngine sharedEngine] requestForAPI:api];
    id request = [NSNull null];
    id requestId = [NSNull null];
    
    if ([task isKindOfClass:[NSURLSessionTask class]]) {
        request = [task currentRequest];
    }
    if (api.hash) {
        requestId = [NSNumber numberWithUnsignedInteger:[api hash]];
    }
    // 生成response对象
    HLURLResult *result = [[HLURLResult alloc] initWithObject:resultObject andError:error];
    HLURLResponse *response = [[HLURLResponse alloc] initWithResult:result
                                                          requestId:requestId
                                                            request:request];
    
    NSDictionary *params = @{kHLRequestDebugKey: api,
                             kHLSessionTaskDebugKey: task,
                             kHLResponseDebugKey: response,
                             kHLQueueDebugKey: self.currentQueue};
    return [[HLDebugMessage alloc] initWithDict:params];
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
    [[self sharedManager] send:api];
}

+ (void)cancel:(HLAPI *)api {
    [[self sharedManager] cancel:api];
}

+ (void)sendGroup:(HLAPIGroup *)group {
    [[self sharedManager] sendGroup:group];
}

+ (void)cancelGroup:(HLAPIGroup *)group {
    [[self sharedManager] cancelGroup:group];
}

+ (void)registerResponseObserver:(id<HLAPIResponseDelegate>)observer {
    [[self sharedManager] registerResponseObserver:observer];
}

+ (void)removeResponseObserver:(id<HLAPIResponseDelegate>)observer {
    [[self sharedManager] removeResponseObserver:observer];
}

+ (void)registerErrorObserver:(id<HLNetworkErrorProtocol>)observer {
    [[self sharedManager] registerErrorObserver:observer];
}

+ (void)removeErrorObserver:(id<HLNetworkErrorProtocol>)observer {
    [[self sharedManager] removeErrorObserver:observer];
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

+ (void)listening:(HLReachabilityBlock)listener {
    [[self sharedManager] listeningWithDomain:[self sharedManager].config.request.baseURL listeningBlock:listener];
}

+ (void)stopListening {
    [[self sharedManager] stopListeningWithDomain:[self sharedManager].config.request.baseURL];
}

- (void)listeningWithDomain:(NSString *)domain listeningBlock:(HLReachabilityBlock)listener {
    if (self.config.enableReachability) {
        @hl_weakify(self)
        [[HLAPIEngine sharedEngine] listeningWithDomain:domain listeningBlock:^(HLReachabilityStatus status) {
            @hl_strongify(self)
            self.reachabilityStatus = status;
            listener(status);
        }];
    }
}

- (void)stopListeningWithDomain:(NSString *)domain {
    [[HLAPIEngine sharedEngine] stopListeningWithDomain:domain];
}

@end
