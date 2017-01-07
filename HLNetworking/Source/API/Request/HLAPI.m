//
//  HLAPI.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/22.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLAPI.h"
#import "HLAPI_InternalParams.h"
#import "HLNetworkConfig.h"
#import "HLAPIManager.h"
#import "HLSecurityPolicyConfig.h"


@implementation HLAPI

#pragma mark - Init
- (instancetype)init {
    self = [super init];
    if (self) {
        _useDefaultParams = YES;
        _objClz = [NSObject class];
        _cURL = nil;
        _accpetContentTypes = [NSSet setWithObjects:
                               @"text/json",
                               @"text/html",
                               @"application/json",
                               @"text/javascript",
                               @"text/plain", nil];
        _header = [HLAPIManager sharedManager].config.request.defaultHeaders;
        _parameters = nil;
        _timeoutInterval = HL_API_REQUEST_TIME_OUT;
        _retryCount = [HLAPIManager sharedManager].config.request.retryCount;
        _cachePolicy = NSURLRequestUseProtocolCachePolicy;
        _requestMethodType = GET;
        _requestSerializerType = RequestHTTP;
        _responseSerializerType = ResponseJSON;
        _securityPolicy = [HLAPIManager sharedManager].config.defaultSecurityPolicy;
    }
    return self;
}

+ (instancetype)API {
    return [[self alloc] init];
}

- (id)copyWithZone:(NSZone *)zone {
    HLAPI *api = [[[self class] alloc] init];
    if (api) {
        api.useDefaultParams = _useDefaultParams;
        api.objClz = _objClz;
        api.cURL = [_cURL copyWithZone:zone];
        api.accpetContentTypes = [_accpetContentTypes copyWithZone:zone];
        api.header = [_header copyWithZone:zone];
        api.parameters = [_parameters copyWithZone:zone];
        api.timeoutInterval = _timeoutInterval;
        api.cachePolicy = _cachePolicy;
        api.requestMethodType = _requestMethodType;
        api.requestSerializerType = _requestSerializerType;
        api.responseSerializerType = _responseSerializerType;
        api.retryCount = _retryCount;
        api.securityPolicy = [_securityPolicy copyWithZone:zone];
        api.delegate = _delegate;
        api.objReformerDelegate = _objReformerDelegate;
        api.baseURL = [_baseURL copyWithZone:zone];
        api.path = [_path copyWithZone:zone];
    }
    return api;
}

#pragma mark - 参数拼接方法
- (HLAPI *(^)(BOOL enable))enableDefaultParams {
    return ^HLAPI* (BOOL enable) {
        self.useDefaultParams = enable;
        return self;
    };
}

- (HLAPI *(^)(NSString *clzName))setResponseClass {
    return ^HLAPI* (NSString *clzName) {
        Class clz = NSClassFromString(clzName);
        if (clz) {
            self.objClz = clz;
        } else {
            self.objClz = nil;
        }
        return self;
    };
}

- (HLAPI *(^)(id<HLAPIRequestDelegate> delegate))setDelegate {
    return ^HLAPI* (id<HLAPIRequestDelegate> delegate) {
        self.delegate = delegate;
        return self;
    };
}

- (HLAPI *(^)(id<HLObjReformerProtocol> delegate))setObjReformerDelegate {
    return ^HLAPI* (id<HLObjReformerProtocol> delegate) {
        self.objReformerDelegate = delegate;
        return self;
    };
}

- (HLAPI* (^)(NSString *baseURL))setBaseURL {
    return ^HLAPI* (NSString *baseURL) {
        self.baseURL = baseURL;
        return self;
    };
}

- (HLAPI *(^)(NSString *path))setPath {
    return ^HLAPI* (NSString *path) {
        self.path = path;
        return self;
    };
}

- (HLAPI* (^)(HLSecurityPolicyConfig *apiSecurityPolicy))setSecurityPolicy {
    return ^HLAPI* (HLSecurityPolicyConfig *apiSecurityPolicy) {
        self.securityPolicy = apiSecurityPolicy;
        return self;
    };
}

- (HLAPI* (^)(HLRequestMethodType requestMethodType))setMethod {
    return ^HLAPI* (HLRequestMethodType requestMethodType) {
        self.requestMethodType = requestMethodType;
        return self;
    };
}

- (HLAPI* (^)(HLRequestSerializerType requestSerializerType))setRequestType {
    return ^HLAPI* (HLRequestSerializerType requestSerializerType) {
        self.requestSerializerType = requestSerializerType;
        return self;
    };
}

- (HLAPI* (^)(HLResponseSerializerType apiResponseSerializerType))setResponseType {
    return ^HLAPI* (HLResponseSerializerType responseSerializerType) {
        self.responseSerializerType = responseSerializerType;
        return self;
    };
}

- (HLAPI* (^)(NSURLRequestCachePolicy apiRequestCachePolicy))setCachePolicy {
    return ^HLAPI* (NSURLRequestCachePolicy apiRequestCachePolicy) {
        self.cachePolicy = apiRequestCachePolicy;
        return self;
    };
}

- (HLAPI* (^)(NSTimeInterval apiRequestTimeoutInterval))setTimeout {
    return ^HLAPI* (NSTimeInterval apiRequestTimeoutInterval) {
        self.timeoutInterval = apiRequestTimeoutInterval;
        return self;
    };
}

- (HLAPI* (^)(NSDictionary<NSString *, id> *parameters))setParams {
    return ^HLAPI* (NSDictionary<NSString *, id> *parameters) {
        self.parameters = parameters;
        return self;
    };
}

- (HLAPI* (^)(NSDictionary<NSString *, id> *parameters))addParams {
    return ^HLAPI* (NSDictionary<NSString *, id> *parameters) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.parameters];
        [dict addEntriesFromDictionary:parameters];
        self.parameters = [dict copy];
        return self;
    };
}

- (HLAPI* (^)(NSDictionary<NSString *, NSString *> *header))setHeader {
    return ^HLAPI* (NSDictionary<NSString *, NSString *> *header) {
        self.header = header;
        return self;
    };
}

- (HLAPI* (^)(NSSet *contentTypes))setAccpetContentTypes {
    return ^HLAPI* (NSSet *contentTypes) {
        self.accpetContentTypes = contentTypes;
        return self;
    };
}

- (HLAPI* (^)(NSString *customURL))setCustomURL {
    return ^HLAPI* (NSString *customURL) {
        self.cURL = customURL;
        NSURL *tmpURL = [NSURL URLWithString:customURL];
        if (tmpURL.host) {
            self.baseURL = [NSString stringWithFormat:@"%@://%@", tmpURL.scheme ?: @"https", tmpURL.host];
            self.path = [NSString stringWithFormat:@"%@", tmpURL.query];
        }
        return self;
    };
}

- (HLAPI *(^)(HLSuccessBlock))success {
    return ^HLAPI* (HLSuccessBlock objBlock) {
        [self setApiSuccessHandler:objBlock];
        return self;
    };
}

- (HLAPI *(^)(HLFailureBlock))failure {
    return ^HLAPI* (HLFailureBlock errorBlock) {
        [self setApiFailureHandler:errorBlock];
        return self;
    };
}

- (HLAPI *(^)(HLProgressBlock))progress {
    return ^HLAPI* (HLProgressBlock progressBlock) {
        [self setApiProgressHandler:progressBlock];
        return self;
    };
}

- (HLAPI *(^)(HLRequestConstructingBodyBlock))formData {
    return ^HLAPI* (HLRequestConstructingBodyBlock bodyBlock) {
        [self setApiRequestConstructingBodyBlock:bodyBlock];
        return self;
    };
}

- (HLAPI *(^)(HLDebugBlock))debug {
    return ^HLAPI* (HLDebugBlock debugBlock) {
        [self setApiDebugHandler:debugBlock];
        return self;
    };
}

#pragma mark - Process
- (void)requestWillBeSent {
    if ([self.delegate respondsToSelector:@selector(requestWillBeSentWithAPI:)]) {
        [self.delegate requestWillBeSentWithAPI:self];
    }
}

- (void)requestDidSent {
    if ([self.delegate respondsToSelector:@selector(requestDidSentWithAPI:)]) {
        [self.delegate requestDidSentWithAPI:self];
    }
}

- (HLAPI *)start {
    [HLAPIManager send:self];
    return self;
}

- (HLAPI *)cancel {
    [HLAPIManager cancel:self];
    return self;
}

#pragma mark - NSObject method
- (NSUInteger)hash {
    NSString *hashStr = nil;
    if (self.cURL) {
        hashStr = [NSString stringWithFormat:@"%@%@?%@", self.header, self.cURL, self.parameters];
    } else {
        hashStr = [NSString stringWithFormat:@"%@%@/%@?%@", self.header, self.baseURL, self.path, self.parameters];
    }
    return [hashStr hash];
}

- (BOOL)isEqualToAPI:(HLAPI *)api {
    return [self hash] == [api hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[HLAPI class]]) return NO;
    return [self isEqualToAPI:(HLAPI *) object];
}

- (NSString *)hashKey {
    return [NSString stringWithFormat:@"%lu", (unsigned long)[self hash]];
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
#if DEBUG
    [desc appendString:@"\n===============HLAPI Start===============\n"];
    [desc appendFormat:@"APIVersion: %@\n", [HLAPIManager sharedManager].config.request.apiVersion ?: @"未设置"];
    [desc appendFormat:@"Class: %@\n", self.objClz];
    [desc appendFormat:@"BaseURL: %@\n", self.baseURL ?: [HLAPIManager sharedManager].config.request.baseURL];
    [desc appendFormat:@"Path: %@\n", self.path ?: @"未设置"];
    [desc appendFormat:@"CustomURL: %@\n", self.cURL ?: @"未设置"];
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
    desc = @"";
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
    dict[@"APIVersion"] = [HLAPIManager sharedManager].config.request.apiVersion ?: @"未设置";
    dict[@"Class"] = [NSString stringWithFormat:@"%@", self.objClz];
    dict[@"BaseURL"] = self.baseURL ?: [HLAPIManager sharedManager].config.request.baseURL;
    dict[@"Path"] = self.path ?: @"未设置";
    dict[@"CustomURL"] = self.cURL ?: @"未设置";
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
