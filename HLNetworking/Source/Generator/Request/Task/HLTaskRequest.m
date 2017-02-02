//
//  HLTaskRequest.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLTaskRequest_InternalParams.h"
#import "HLURLRequest_InternalParams.h"
#import "HLNetworkManager.h"
#import "HLNetworkConfig.h"
#import "HLSecurityPolicyConfig.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HLTaskRequest
#pragma mark - initialize method
- (instancetype)init {
    self = [super init];
    if (self) {
        _requestTaskType = Download;
        NSString *baseResumePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"com.qkhl.HLNetworking/downloadDict"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:baseResumePath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:baseResumePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _resumePath = [baseResumePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.arc", (unsigned long)self.hash]];
    }
    return self;
}
- (id)copyWithZone:(NSZone *)zone {
    HLTaskRequest *request = [super copyWithZone:zone];
    if (request) {
        request.filePath = [_filePath copyWithZone:zone];
        request.resumePath = [_resumePath copyWithZone:zone];
        request.requestTaskType = _requestTaskType;
    }
    return request;
}

#pragma mark - parameters append method
// 设置下载或者上传的本地文件路径
- (HLTaskRequest *(^)(NSString *filePath))setFilePath {
    return ^HLTaskRequest* (NSString *filePath) {
        [self.lock lock];
        self.filePath = filePath;
        [self.lock unlock];
        return self;
    };
}
// 设置task的类型（上传/下载）
- (HLTaskRequest *(^)(HLRequestTaskType requestTaskType))setTaskType {
    return ^HLTaskRequest* (HLRequestTaskType requestTaskType) {
        [self.lock lock];
        self.requestTaskType = requestTaskType;
        [self.lock unlock];
        return self;
    };
}

#pragma mark - helper
- (NSUInteger)hash {
    NSString *hashStr;
    if (self.customURL) {
        hashStr = self.customURL;
    } else {
        hashStr = [NSString stringWithFormat:@"%@/%@", self.baseURL, self.path];
    }
    return [hashStr hash];
}
- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
#if DEBUG
    [desc appendString:@"\n===============HLTask Start===============\n"];
    [desc appendFormat:@"Class: %@\n", self.class];
    [desc appendFormat:@"BaseURL: %@\n", self.baseURL ?: [HLNetworkManager config].request.baseURL];
    [desc appendFormat:@"Path: %@\n", self.path ?: @"未设置"];
    [desc appendFormat:@"CustomURL: %@\n", self.customURL ?: @"未设置"];
    [desc appendFormat:@"ResumePath: %@", self.resumePath];
    [desc appendFormat:@"CachePath: %@", self.filePath];
    [desc appendFormat:@"TimeoutInterval: %f\n", self.timeoutInterval];
    [desc appendFormat:@"SecurityPolicy: %@\n", self.securityPolicy];
    [desc appendFormat:@"RequestTaskType: %@\n", [self getRequestTaskTypeString:self.requestTaskType]];
    [desc appendFormat:@"CachePolicy: %@\n", [self getCachePolicyString:self.cachePolicy]];
    [desc appendString:@"===============End===============\n"];
#else
    desc = [NSMutableString stringWithFormat:@""];
#endif
    return desc;
}
- (NSString *)getRequestTaskTypeString:(HLRequestTaskType)type {
    switch (type) {
        case Download:
            return @"Download";
            break;
        case Upload:
            return @"Upload";
            break;
        default:
            return @"Download";
            break;
    }
}
- (NSString *)getCachePolicyString:(NSURLRequestCachePolicy)policy {
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
            return @"NSURLRequestUseProtocolCachePolicy";
            break;
    }
}
- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"APIVersion"] = [HLNetworkManager config].request.apiVersion ?: @"未设置";
    dict[@"BaseURL"] = self.baseURL ?: [HLNetworkManager config].request.baseURL;
    dict[@"Path"] = self.path ?: @"未设置";
    dict[@"CustomURL"] = self.customURL ?: @"未设置";
    dict[@"ResumePath"] = self.resumePath ?: @"未设置";
    dict[@"TimeoutInterval"] = [NSString stringWithFormat:@"%f", self.timeoutInterval];
    dict[@"SecurityPolicy"] = [self.securityPolicy toDictionary];
    dict[@"RequestMethodType"] = [self getRequestTaskTypeString:self.requestTaskType];
    dict[@"CachePolicy"] = [self getCachePolicyString:self.cachePolicy];
    return dict;
}
@end
#pragma clang diagnostic pop
