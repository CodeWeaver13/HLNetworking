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
#import "HLAPIRequestDelegate.h"

HLDebugKey const kHLSessionTaskDebugKey = @"kHLSessionTaskDebugKey";
HLDebugKey const kHLAPIDebugKey = @"kHLAPIDebugKey";
HLDebugKey const kHLErrorDebugKey = @"kHLErrorDebugKey";
HLDebugKey const kHLOriginalRequestDebugKey = @"kHLOriginalRequestDebugKey";
HLDebugKey const kHLCurrentRequestDebugKey = @"kHLCurrentRequestDebugKey";
HLDebugKey const kHLResponseDebugKey = @"kHLResponseDebugKey";

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
        _header = nil;
        _parameters = nil;
        _timeoutInterval = HL_API_REQUEST_TIME_OUT;
        _cachePolicy = NSURLRequestUseProtocolCachePolicy;
        _requestMethodType = GET;
        _requestSerializerType = RequestHTTP;
        _responseSerializerType = ResponseJSON;
        // 为了方便，在Debug模式下使用None来保证用Charles之类可以抓到HTTPS报文Production下，则用Pinning Certification PublicKey 来防止中间人攻击
#ifdef DEBUG
        _securityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:HLSSLPinningModeNone];
#else
        _securityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:HLSSLPinningModePublicKey];
#endif
    }
    return self;
}

+ (instancetype)API {
    return [[self alloc] init];
}

- (HLAPI *(^)(BOOL enable))enableDefaultParams {
    return ^HLAPI* (BOOL enable) {
        self.useDefaultParams = enable;
        return self;
    };
}

- (HLAPI *(^)(NSString *clzName))setResponseClass {
    return ^HLAPI* (NSString *clzName) {
        self.objClz = NSClassFromString(clzName);
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
    [[HLAPIManager sharedManager] sendAPIRequest:((HLAPI *)self)];
    return self;
}

- (HLAPI *)cancel {
    [[HLAPIManager sharedManager] cancelAPIRequest:((HLAPI *)self)];
    return self;
}

#pragma mark - NSObject method
- (NSUInteger)hash {
    NSString *hashStr = nil;
    if (self.cURL) {
        hashStr = [NSString stringWithFormat:@"%@?%@", self.cURL, self.parameters];
    } else {
        hashStr = [NSString stringWithFormat:@"%@/%@?%@", self.baseURL, self.path, self.parameters];
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

- (NSString *)description {
    NSString *desc;
#if DEBUG
    desc = [NSString stringWithFormat:@"\n===============HLAPI===============\nAPIVersion: %@\nClass: %@\nBaseURL: %@\nPath: %@\nCustomURL: %@\nParameters: %@\nHeader: %@\nContentTypes: %@\nTimeoutInterval: %f\nSecurityPolicy: %@\nRequestMethodType: %@\nRequestSerializerType: %@\nResponseSerializerType: %@\nCachePolicy: %@\n===============end===============\n\n",
            [HLAPIManager sharedManager].config.apiVersion ?: @"未设置",
            self.class, self.baseURL ?: [HLAPIManager sharedManager].config.baseURL,
            self.path, self.cURL ?: @"未设置",
            self.parameters ?: @"未设置", self.header ?: @"未设置",
            self.accpetContentTypes,
            self.timeoutInterval,
            self.securityPolicy,
            [self getRequestMethodString:self.requestMethodType],
            [self getRequestSerializerTypeString: self.requestSerializerType],
            [self getResponseSerializerTypeString: self.responseSerializerType],
            [self getCachePolicy:self.cachePolicy]];
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

#pragma mark - getter / lazy load


@end
