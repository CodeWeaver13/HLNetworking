//
//  HLTask.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/25.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLTask.h"
#import "HLTask_InternalParams.h"
#import "HLTaskManager.h"
#import "HLSecurityPolicyConfig.h"
#import "HLNetworkConfig.h"

@implementation HLTask

#pragma mark - init
+ (instancetype)task {
    HLTask *task = [[HLTask alloc] init];
    return task;
}

#pragma mark - Process

- (HLTask *)start {
    [[HLTaskManager shared] sendTaskRequest:((HLTask *)self)];
    return self;
}

- (HLTask *)cancel {
    [[HLTaskManager shared] cancelTaskRequest:((HLTask *)self)];
    return self;
}

- (HLTask *)resume {
    [[HLTaskManager shared] resumeTaskRequest:((HLTask *)self)];
    return self;
}

- (HLTask *)pause {
    [[HLTaskManager shared] pauseTaskRequest:((HLTask *)self)];
    return self;
}

#pragma mark - NSObject
- (NSUInteger)hash {
    NSString *hashStr;
    if (self.taskURL) {
        hashStr = self.taskURL;
    } else {
        hashStr = [NSString stringWithFormat:@"%@/%@", self.baseURL, self.path];
    }
    return [hashStr hash];
}

- (BOOL)isEqualToTask:(HLTask *)task {
    return [self hash] == [task hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[HLTask class]]) return NO;
    return [self isEqualToTask:(HLTask *) object];
}

- (NSString *)description {
    NSString *desc;
#if DEBUG
    desc = [NSString stringWithFormat:@"\n===============HLTask===============\nClass: %@\nBaseURL: %@\nPath: %@\nTaskURL: %@\nResumePath: %@\nCachePath: %@\nTimeoutInterval: %f\nSecurityPolicy: %@\nRequestTaskType: %lu\nCachePolicy: %lu\n===============end===============\n\n", self.class, self.baseURL ?: [HLTaskManager shared].config.baseURL, self.path ?: @"未设置", self.taskURL ?: @"未设置", self.resumePath, self.filePath, self.timeoutInterval, self.securityPolicy, self.requestTaskType, self.cachePolicy];
#else
    desc = @"";
#endif
    return desc;
}

#pragma mark - setter
/**
 设置HLAPI的requestDelegate
 */
- (HLTask *(^)(id<HLTaskRequestDelegate> delegate))setDelegate {
    return ^HLTask* (id<HLTaskRequestDelegate> delegate) {
        self.delegate = delegate;
        return self;
    };
}

- (HLTask *(^)(NSString *taskURL))setTaskURL {
    return ^HLTask* (NSString *taskURL) {
        self.taskURL = taskURL;
        return self;
    };
}

- (HLTask *(^)(NSString *baseURL))setBaseURL {
    return ^HLTask* (NSString *baseURL) {
        self.baseURL = baseURL;
        return self;
    };
}

- (HLTask *(^)(NSString *path))setPath {
    return ^HLTask* (NSString *path) {
        self.path = path;
        return self;
    };
}

- (HLTask *(^)(NSString *filePath))setFilePath {
    return ^HLTask* (NSString *filePath) {
        self.filePath = filePath;
        return self;
    };
}

- (HLTask* (^)(HLSecurityPolicyConfig *apiSecurityPolicy))setSecurityPolicy {
    return ^HLTask* (HLSecurityPolicyConfig *apiSecurityPolicy) {
        self.securityPolicy = apiSecurityPolicy;
        return self;
    };
}

- (void)requestWillBeSent {
    if ([self.delegate respondsToSelector:@selector(requestWillBeSentWithTask:)]) {
        [self.delegate requestWillBeSentWithTask:self];
    }
}

- (void)requestDidSent {
    if ([self.delegate respondsToSelector:@selector(requestDidSentWithTask:)]) {
        [self.delegate requestDidSentWithTask:self];
    }
}

#pragma mark - getter / lazy load
- (NSString *)baseURL {
    if (!_baseURL) {
        _baseURL = [HLTaskManager shared].config.baseURL;
    }
    return _baseURL;
}

- (NSString *)path {
    return nil;
}

- (NSString *)resumePath {
    if (!_resumePath) {
        NSString *baseResumePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"com.qkhl.HLNetworking/downloadDict"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:baseResumePath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:baseResumePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _resumePath = [baseResumePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.arc", self.hash]];
        
    }
    return _resumePath;
}

/**
 *  为了方便，在Debug模式下使用None来保证用Charles之类可以抓到HTTPS报文
 *  Production下，则用Pinning Certification PublicKey 来防止中间人攻击
 */
- (nonnull HLSecurityPolicyConfig *)securityPolicy {
    if (_securityPolicy) {
        return _securityPolicy;
    } else {
        HLSecurityPolicyConfig *securityPolicy;
#ifdef DEBUG
        securityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:None];
#else
        securityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:PublicKey];
#endif
        return securityPolicy;
    }
}

- (HLRequestTaskType)requestTaskType {
    if (_requestTaskType) {
        return _requestTaskType;
    } else {
        return Download;
    }
}
@end
