//
//  HLURLRequest.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLURLRequest.h"
#import "HLURLRequest_InternalParams.h"
#import "HLNetworkConfig.h"
#import "HLNetworkMacro.h"
#import "HLNetworkManager.h"
#import "HLSecurityPolicyConfig.h"


@implementation HLURLRequest
#pragma mark - initialize method
- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = [[NSLock alloc] init];
        _lock.name = @"com.qkhl.wangshiyu13.networking.urlrequest.lock";
        _cURL = nil;
        _path = nil;
        _baseURL = [HLNetworkManager config].request.baseURL;
        _timeoutInterval = HL_API_REQUEST_TIME_OUT;
        _retryCount = [HLNetworkManager config].request.retryCount;
        _cachePolicy = NSURLRequestUseProtocolCachePolicy;
        _securityPolicy = [HLNetworkManager config].defaultSecurityPolicy;
    }
    return self;
}

+ (instancetype)request {
    return [[self alloc] init];
}

- (id)copyWithZone:(NSZone *)zone {
    HLURLRequest *request = [[[self class] alloc] init];
    if (request) {
        request.cURL = [_cURL copyWithZone:zone];
        request.path = [_path copyWithZone:zone];
        request.baseURL = [_baseURL copyWithZone:zone];
        request.timeoutInterval = _timeoutInterval;
        request.retryCount = _retryCount;
        request.securityPolicy = [_securityPolicy copyWithZone:zone];
        request.cachePolicy = _cachePolicy;
        request.delegate = _delegate;
    }
    return request;
}

#pragma mark - parameters append method
// 设置HLAPI的requestDelegate
- (__kindof HLURLRequest *(^)(id<HLURLRequestDelegate> delegate))setDelegate {
    return ^HLURLRequest* (id<HLURLRequestDelegate> delegate) {
        [self.lock lock];
        self.delegate = delegate;
        [self.lock unlock];
        return self;
    };
}
// 设置API的baseURL，该参数会覆盖config中的baseURL
- (__kindof HLURLRequest *(^)(NSString *baseURL))setBaseURL {
    return ^HLURLRequest* (NSString *baseURL) {
        [self.lock lock];
        self.baseURL = baseURL;
        [self.lock unlock];
        return self;
    };
}
// urlQuery，baseURL后的地址
- (__kindof HLURLRequest *(^)(NSString *path))setPath {
    return ^HLURLRequest* (NSString *path) {
        [self.lock lock];
        self.path = path;
        [self.lock unlock];
        return self;
    };
}
// 自定义的RequestUrl，该参数会无视任何baseURL的设置，优先级最高
- (__kindof HLURLRequest *(^)(NSString *customURL))setCustomURL {
    return ^HLURLRequest* (NSString *customURL) {
        [self.lock unlock];
        self.cURL = customURL;
        NSURL *tmpURL = [NSURL URLWithString:customURL];
        if (tmpURL.host) {
            self.baseURL = [NSString stringWithFormat:@"%@://%@", tmpURL.scheme ?: @"https", tmpURL.host];
            self.path = [NSString stringWithFormat:@"%@", tmpURL.query];
        }
        [self.lock unlock];
        return self;
    };
}
// HTTPS 请求的Security策略
- (__kindof HLURLRequest *(^)(HLSecurityPolicyConfig *securityPolicy))setSecurityPolicy {
    return ^HLURLRequest* (HLSecurityPolicyConfig *securityPolicy) {
        [self.lock lock];
        self.securityPolicy = securityPolicy;
        [self.lock unlock];
        return self;
    };
}
// HTTP 请求的Cache策略
- (__kindof HLURLRequest *(^)(NSURLRequestCachePolicy requestCachePolicy))setCachePolicy {
    return ^HLURLRequest* (NSURLRequestCachePolicy requestCachePolicy) {
        [self.lock lock];
        self.cachePolicy = requestCachePolicy;
        [self.lock unlock];
        return self;
    };
}
// HTTP 请求超时的时间，默认为15秒
- (__kindof HLURLRequest *(^)(NSTimeInterval requestTimeoutInterval))setTimeout {
    return ^HLURLRequest* (NSTimeInterval requestTimeoutInterval) {
        [self.lock lock];
        self.timeoutInterval = requestTimeoutInterval;
        [self.lock unlock];
        return self;
    };
}

#pragma mark - handler block function
/**
 API完成后的成功回调
 写法：
 .success(^(id obj) {
 dosomething
 })
 */
- (__kindof HLURLRequest *(^)(HLSuccessBlock))success {
    return ^HLURLRequest* (HLSuccessBlock objBlock) {
        [self.lock lock];
        self.successHandler = objBlock;
        [self.lock unlock];
        return self;
    };
}
/**
 API完成后的失败回调
 写法：
 .failure(^(NSError *error) {
 
 })
 */
- (__kindof HLURLRequest *(^)(HLFailureBlock))failure {
    return ^HLURLRequest* (HLFailureBlock errorBlock) {
        [self.lock lock];
        self.failureHandler = errorBlock;
        [self.lock unlock];
        return self;
    };
}
/**
 API上传、下载等长时间执行的Progress进度
 写法：
 .progress(^(NSProgress *proc){
 NSLog(@"当前进度：%@", proc);
 })
 */
- (__kindof HLURLRequest *(^)(HLProgressBlock))progress {
    return ^HLURLRequest* (HLProgressBlock progressBlock) {
        [self.lock lock];
        self.progressHandler = progressBlock;
        [self.lock unlock];
        return self;
    };
}
/**
 用于Debug的Block
 block内返回HLDebugMessage对象
 */
- (__kindof HLURLRequest *(^)(HLDebugBlock))debug {
    return ^HLURLRequest* (HLDebugBlock debugBlock) {
        [self.lock lock];
        self.debugHandler = debugBlock;
        [self.lock unlock];
        return self;
    };
}

#pragma mark - process
// 开启API 请求
- (__kindof HLURLRequest *)start {
    [HLNetworkManager send:self];
    return self;
}
// 取消API 请求
- (__kindof HLURLRequest *)cancel {
    [HLNetworkManager cancel:self];
    return self;
}
// 继续Task
- (__kindof HLURLRequest *)resume {
    [HLNetworkManager resume:self];
    return self;
}
// 暂停Task
- (__kindof HLURLRequest *)pause {
    [HLNetworkManager pause:self];
    return self;
}

#pragma mark - helper
- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"APIVersion"] = [HLNetworkManager config].request.apiVersion ?: @"未设置";
    dict[@"BaseURL"] = self.baseURL ?: [HLNetworkManager config].request.baseURL;
    dict[@"Path"] = self.path ?: @"未设置";
    dict[@"CustomURL"] = self.customURL ?: @"未设置";
    dict[@"TimeoutInterval"] = [NSString stringWithFormat:@"%f", self.timeoutInterval];
    dict[@"SecurityPolicy"] = [self.securityPolicy toDictionary];
    dict[@"CachePolicy"] = [self getCachePolicy:self.cachePolicy];
    return dict;
}
- (NSString *)hashKey {
    return [NSString stringWithFormat:@"%lu", (unsigned long)[self hash]];
}
- (NSUInteger)hash {
    NSString *hashStr = nil;
    if (self.customURL) {
        hashStr = [NSString stringWithFormat:@"%@",
                   self.customURL];
    } else {
        hashStr = [NSString stringWithFormat:@"%@/%@",
                   self.baseURL,
                   self.path];
    }
    return [hashStr hash];
}
- (BOOL)isEqualToRequest:(HLURLRequest *)request {
    return [self hash] == [request hash];
}
- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[HLURLRequest class]]) return NO;
    return [self isEqualToRequest:(HLURLRequest *) object];
}
- (NSString *)getCachePolicy:(NSURLRequestCachePolicy)policy {
    switch (policy) {
        case NSURLRequestUseProtocolCachePolicy:
            return @"NSURLRequestUseProtocolCachePolicy";
            break;
        case NSURLRequestReloadIgnoringLocalCacheData:
            return @"NSURLRequestReloadIgnoringLocalCacheData";
            break;
        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
            return @"NSURLRequestReloadIgnoringLocalAndRemoteCacheData";
            break;
        case NSURLRequestReturnCacheDataElseLoad:
            return @"NSURLRequestReturnCacheDataElseLoad";
            break;
        case NSURLRequestReturnCacheDataDontLoad:
            return @"NSURLRequestReturnCacheDataDontLoad";
            break;
        case NSURLRequestReloadRevalidatingCacheData:
            return @"NSURLRequestReloadRevalidatingCacheData";
            break;
        default:
            return @"NULL";
            break;
    }
}
@end
