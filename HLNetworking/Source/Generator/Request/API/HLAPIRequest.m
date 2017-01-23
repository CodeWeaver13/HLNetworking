//
//  HLAPIRequest.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLURLRequest_InternalParams.h"
#import "HLAPIRequest_InternalParams.h"
#import "HLNetworkManager.h"
#import "HLNetworkConfig.h"
#import "HLSecurityPolicyConfig.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation HLAPIRequest
#pragma mark - initialize method
- (instancetype)init {
    self = [super init];
    if (self) {
        _useDefaultParams = YES;
        _objClz = [NSObject class];
        _accpetContentTypes = [NSSet setWithObjects:
                               @"text/json",
                               @"text/html",
                               @"application/json",
                               @"text/javascript",
                               @"text/plain", nil];
        _header = [HLNetworkManager config].request.defaultHeaders;
        _parameters = nil;
        _requestMethodType = GET;
        _requestSerializerType = RequestHTTP;
        _responseSerializerType = ResponseJSON;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    HLAPIRequest *request = [super copyWithZone:zone];
    if (request) {
        request.useDefaultParams = _useDefaultParams;
        request.objClz = _objClz;
        request.accpetContentTypes = [_accpetContentTypes copyWithZone:zone];
        request.header = [_header copyWithZone:zone];
        request.parameters = [_parameters copyWithZone:zone];
        request.requestMethodType = _requestMethodType;
        request.requestSerializerType = _requestSerializerType;
        request.responseSerializerType = _responseSerializerType;
        request.objReformerDelegate = _objReformerDelegate;
    }
    return request;
}

#pragma mark - parameters append method
/**
 进行JSON -> Model 数据的转换工作的Delegate
 如果设置了ReformerDelegate，则使用ReformerDelegate的obj解析，否则直接返回
 提供该Delegate主要用于Reformer的不相关代码的解耦工作
 
 param responseObject 请求回调对象
 param error          错误信息
 
 @return 请求结果数据
 */
- (HLAPIRequest *(^)(id<HLReformerDelegate> delegate))setObjReformerDelegate {
    return ^HLAPIRequest* (id<HLReformerDelegate> delegate) {
        self.objReformerDelegate = delegate;
        return self;
    };
}
/**
 HTTP 请求的返回可接受的内容类型
 默认为：[NSSet setWithObjects:
 @"text/json",
 @"text/html",
 @"application/json",
 @"text/javascript", nil];
 */
- (HLAPIRequest *(^)(NSSet *contentTypes))setAccpetContentTypes {
    return ^HLAPIRequest* (NSSet *contentTypes) {
        self.accpetContentTypes = contentTypes;
        return self;
    };
}
// 是否使用APIManager.config的默认参数
- (HLAPIRequest *(^)(BOOL enable))enableDefaultParams {
    return ^HLAPIRequest* (BOOL enable) {
        self.useDefaultParams = enable;
        return self;
    };
}
// 设置HLAPI对应的返回值模型类型
- (HLAPIRequest *(^)(NSString *clzName))setResponseClass {
    return ^HLAPIRequest* (NSString *clzName) {
        Class clz = NSClassFromString(clzName);
        if (clz) {
            self.objClz = clz;
        } else {
            self.objClz = nil;
        }
        return self;
    };
}
// 请求方法 GET POST等
- (HLAPIRequest *(^)(HLRequestMethodType requestMethodType))setMethod {
    return ^HLAPIRequest* (HLRequestMethodType requestMethodType) {
        self.requestMethodType = requestMethodType;
        return self;
    };
}
// Request 序列化类型：JSON, HTTP, 见HLRequestSerializerType
- (HLAPIRequest *(^)(HLRequestSerializerType requestSerializerType))setRequestType {
    return ^HLAPIRequest* (HLRequestSerializerType requestSerializerType) {
        self.requestSerializerType = requestSerializerType;
        return self;
    };
}
// Response 序列化类型： JSON, HTTP
- (HLAPIRequest *(^)(HLResponseSerializerType responseSerializerType))setResponseType {
    return ^HLAPIRequest* (HLResponseSerializerType responseSerializerType) {
        self.responseSerializerType = responseSerializerType;
        return self;
    };
}
// 请求中的参数，每次设置都会覆盖之前的内容
- (HLAPIRequest *(^)(NSDictionary<NSString *, id> *parameters))setParams {
    return ^HLAPIRequest* (NSDictionary<NSString *, id> *parameters) {
        self.parameters = parameters;
        return self;
    };
}
// 请求中的参数，每次设置都是添加新参数，不会覆盖之前的内容
- (HLAPIRequest *(^)(NSDictionary<NSString *, id> *parameters))addParams {
    return ^HLAPIRequest* (NSDictionary<NSString *, id> *parameters) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.parameters];
        [dict addEntriesFromDictionary:parameters];
        self.parameters = [dict copy];
        return self;
    };
}
// HTTP 请求的头部区域自定义，默认为nil
- (HLAPIRequest *(^)(NSDictionary<NSString *, NSString *> *header))setHeader {
    return ^HLAPIRequest* (NSDictionary<NSString *, NSString *> *header) {
        self.header = header;
        return self;
    };
}

#pragma mark - handler block function
- (HLAPIRequest *(^)(HLRequestConstructingBodyBlock))formData {
    return ^HLAPIRequest* (HLRequestConstructingBodyBlock bodyBlock) {
        [self setRequestConstructingBodyBlock:bodyBlock];
        return self;
    };
}

#pragma mark - helper
- (NSUInteger)hash {
    NSString *hashStr = nil;
    if (self.customURL) {
        hashStr = [NSString stringWithFormat:@"%@%@?%@?%lu",
                   self.header,
                   self.customURL,
                   self.parameters,
                   (unsigned long)self.requestMethodType];
    } else {
        hashStr = [NSString stringWithFormat:@"%@%@/%@?%@?%lu",
                   self.header,
                   self.baseURL,
                   self.path,
                   self.parameters,
                   (unsigned long)self.requestMethodType];
    }
    return [hashStr hash];
}
// 拼接打印信息
- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
#if DEBUG
    [desc appendString:@"\n===============HLAPI Start===============\n"];
    [desc appendFormat:@"APIVersion: %@\n", [HLNetworkManager config].request.apiVersion ?: @"未设置"];
    [desc appendFormat:@"Class: %@\n", self.objClz];
    [desc appendFormat:@"BaseURL: %@\n", self.baseURL ?: [HLNetworkManager config].request.baseURL];
    [desc appendFormat:@"Path: %@\n", self.path ?: @"未设置"];
    [desc appendFormat:@"CustomURL: %@\n", self.customURL ?: @"未设置"];
    [desc appendFormat:@"Parameters: %@\n", self.parameters ?: @"未设置"];
    [desc appendFormat:@"Header: %@\n", self.header ?: @"未设置"];
    [desc appendFormat:@"ContentTypes: %@\n", self.accpetContentTypes];
    [desc appendFormat:@"TimeoutInterval: %f\n", self.timeoutInterval];
    [desc appendFormat:@"SecurityPolicy: %@\n", self.securityPolicy];
    [desc appendFormat:@"RequestMethodType: %@\n", [self getRequestMethodString:self.requestMethodType]];
    [desc appendFormat:@"RequestSerializerType: %@\n", [self getRequestSerializerTypeString: self.requestSerializerType]];
    [desc appendFormat:@"ResponseSerializerType: %@\n", [self getResponseSerializerTypeString: self.responseSerializerType]];
    [desc appendFormat:@"CachePolicy: %@\n", [self getCachePolicy:self.cachePolicy]];
    [desc appendString:@"=================HLAPI End================\n"];
#else
    desc = [NSMutableString stringWithFormat:@""];
#endif
    return desc;
}
- (NSString *)debugDescription {
    return self.description;
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
- (NSString *)getRequestMethodString:(HLRequestMethodType)method {
    switch (method) {
        case GET:
            return @"GET";
            break;
        case POST:
            return @"POST";
            break;
        case HEAD:
            return @"HEAD";
            break;
        case PUT:
            return @"PUT";
            break;
        case PATCH:
            return @"PATCH";
            break;
        case DELETE:
            return @"PATCH";
            break;
        default:
            return @"NULL";
            break;
    }
}
- (NSString *)getRequestSerializerTypeString:(HLRequestSerializerType)type {
    switch (type) {
        case RequestJSON:
            return @"RequestJSON";
            break;
        case RequestPlist:
            return @"RequestPlist";
            break;
        case RequestHTTP:
            return @"RequestHTTP";
            break;
        default:
            return @"NULL";
            break;
    }
}
- (NSString *)getResponseSerializerTypeString:(HLResponseSerializerType)type {
    switch (type) {
        case ResponseXML:
            return @"ResponseXML";
            break;
        case ResponsePlist:
            return @"ResponsePlist";
            break;
        case ResponseHTTP:
            return @"ResponseHTTP";
            break;
        case ResponseJSON:
            return @"ResponseJSON";
            break;
        default:
            return @"NULL";
            break;
    }
}
- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"APIVersion"] = [HLNetworkManager config].request.apiVersion ?: @"未设置";
    dict[@"Class"] = [NSString stringWithFormat:@"%@", self.objClz];
    dict[@"BaseURL"] = self.baseURL ?: [HLNetworkManager config].request.baseURL;
    dict[@"Path"] = self.path ?: @"未设置";
    dict[@"CustomURL"] = self.customURL ?: @"未设置";
    dict[@"Parameters"] = self.parameters ?: @"未设置";
    dict[@"Header"] = self.header ?: @"未设置";
    dict[@"ContentTypes"] = [NSString stringWithFormat:@"%@", self.accpetContentTypes];
    dict[@"TimeoutInterval"] = [NSString stringWithFormat:@"%f", self.timeoutInterval];
    dict[@"SecurityPolicy"] = [self.securityPolicy toDictionary];
    dict[@"RequestMethodType"] = [self getRequestMethodString:self.requestMethodType];
    dict[@"RequestSerializerType"] = [self getRequestSerializerTypeString: self.requestSerializerType];
    dict[@"ResponseSerializerType"] = [self getResponseSerializerTypeString: self.responseSerializerType];
    dict[@"CachePolicy"] = [self getCachePolicy:self.cachePolicy];
    return dict;
}
@end
#pragma clang diagnostic pop
