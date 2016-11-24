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

@implementation HLAPI

#pragma mark - Init
+ (instancetype)API {
    HLAPI *api = [[HLAPI alloc] init];
    return api;
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


- (HLAPI* (^)(NSDictionary<NSString *, NSObject *> *parameters))setParams {
    return ^HLAPI* (NSDictionary<NSString *, NSObject *> *parameters) {
        self.parameters = parameters;
        return self;
    };
}

- (HLAPI* (^)(NSDictionary<NSString *, NSObject *> *parameters))addParams {
    return ^HLAPI* (NSDictionary<NSString *, NSObject *> *parameters) {
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

- (HLAPI *(^)(ReObjBlock))success {
    return ^HLAPI* (ReObjBlock objBlock) {
        [self setApiSuccessHandler:objBlock];
        return self;
    };
}

- (HLAPI *(^)(ReErrorBlock))failure {
    return ^HLAPI* (ReErrorBlock errorBlock) {
        [self setApiFailureHandler:errorBlock];
        return self;
    };
}

- (HLAPI *(^)(ProgressBlock))progress {
    return ^HLAPI* (ProgressBlock progressBlock) {
        [self setApiProgressHandler:progressBlock];
        return self;
    };
}

- (HLAPI *(^)(RequestConstructingBodyBlock))formData {
    return ^HLAPI* (RequestConstructingBodyBlock bodyBlock) {
        [self setApiRequestConstructingBodyBlock:bodyBlock];
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
    [[HLAPIManager shared] sendAPIRequest:((HLAPI *)self)];
    return self;
}

- (HLAPI *)cancel {
    [[HLAPIManager shared] cancelAPIRequest:((HLAPI *)self)];
    return self;
}

#pragma mark - NSObject method
- (NSUInteger)hash {
    NSString *hashStr;
    if (self.cURL) {
        hashStr = [NSString stringWithFormat:@"%@?%@", self.cURL, self.parameters];
    } else {
        hashStr = [NSString stringWithFormat:@"%@/%@?%@", self.path, self.baseURL, self.parameters];
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
            [HLAPIManager shared].config.apiVersion ?: @"未设置",
            self.class, self.baseURL ?: [HLAPIManager shared].config.baseURL,
            self.path, self.cURL ?: @"未设置",
            self.parameters ?: @"未设置", self.header,
            self.accpetContentTypes,
            self.timeoutInterval,
            self.securityPolicy,
            [self getRequestMethodString:self.requestMethodType],
            self.requestSerializerType == RequestHTTP ? @"HTTP" : @"JSON",
            self.responseSerializerType == ResponseHTTP ? @"HTTP" : @"JSON",
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

#pragma mark - getter / lazy load
- (NSString *)baseURL {
    return nil;
}

- (BOOL)useDefaultParams {
    if (_useDefaultParams) {
        return _useDefaultParams;
    } else {
        return YES;
    }
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
        securityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:HLSSLPinningModeNone];
#else
        securityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:HLSSLPinningModePublicKey];
#endif
        return securityPolicy;
    }
}

- (HLRequestMethodType)requestMethodType {
    if (_requestMethodType) {
        return _requestMethodType;
    } else {
        return GET;
    }
}

- (HLRequestSerializerType)requestSerializerType {
    if (_requestSerializerType) {
        return _requestSerializerType;
    } else {
        return RequestHTTP;
    }
}

- (HLResponseSerializerType)responseSerializerType {
    if (_responseSerializerType) {
        return _responseSerializerType;
    } else {
        return ResponseJSON;
    }
}

- (NSURLRequestCachePolicy)cachePolicy {
    if (_cachePolicy) {
        return _cachePolicy;
    } else {
        return NSURLRequestUseProtocolCachePolicy;
    }
}

- (NSTimeInterval)timeoutInterval {
    if (_timeoutInterval) {
        return _timeoutInterval;
    } else {
        return HL_API_REQUEST_TIME_OUT;
    }
}

- (NSDictionary<NSString *, NSObject *> *)parameters {
    if (_parameters) {
        return _parameters;
    } else {
        return nil;
    }
}

- (NSDictionary<NSString *, NSString *> *)header {
    if (_header) {
        return _header;
    } else {
        return nil;
    }
}

- (NSSet *)accpetContentTypes {
    if (_accpetContentTypes) {
        return _accpetContentTypes;
    } else {
        return [NSSet setWithObjects:
                @"text/json",
                @"text/html",
                @"application/json",
                @"text/javascript", nil];;
    }
}

- (NSString *)cURL {
    if (_cURL) {
        return _cURL;
    } else {
        return nil;
    }
}

- (Class)objClz {
    if (_objClz) {
        return _objClz;
    } else {
        return [NSObject class];
    }
}
@end
