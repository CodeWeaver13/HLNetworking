//
//  HLAPI.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/22.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLAPI.h"
#import "HLNetworkConfig.h"
#import "HLAPIManager.h"
#import "HLSecurityPolicyConfig.h"



@interface HLAPI ()

@property (nonatomic, weak, nullable) id<HLRequestDelegate> delegate;
@property (nonatomic, weak, nullable) id<HLObjReformerProtocol> objReformerDelegate;
@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong)HLSecurityPolicyConfig *securityPolicy;
@property (nonatomic, assign)HLRequestMethodType requestMethodType;
@property (nonatomic, assign)HLRequestSerializerType requestSerializerType;
@property (nonatomic, assign)HLResponseSerializerType responseSerializerType;
@property (nonatomic, assign)NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, assign)NSTimeInterval timeoutInterval;
@property (nonatomic, copy) NSDictionary<NSString *, NSObject *> *parameters;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *header;
@property (nonatomic, copy) NSSet *contentTypes;
@property (nonatomic, copy) NSString *cURL;

@property (nonatomic, copy, nullable) void (^apiSuccessHandler)(_Nonnull id responseObject);
@property (nonatomic, copy, nullable) void (^apiFailureHandler)(NSError * _Nullable error);
@property (nonatomic, copy, nullable) void (^apiProgressHandler)(NSProgress * _Nullable progress);
@property (nonatomic, copy, nullable) void (^apiRequestConstructingBodyBlock)(id<HLMultipartFormDataProtocol> _Nonnull formData);
@end

@implementation HLAPI

#pragma mark - Init
+ (instancetype)API {
    HLAPI *api = [[HLAPI alloc] init];
    return api;
}

- (HLAPI *(^)(id<HLRequestDelegate> delegate))setDelegate {
    return ^HLAPI* (id<HLRequestDelegate> delegate) {
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


- (HLAPI* (^)(NSDictionary<NSString *, NSString *> *header))setHeader {
    return ^HLAPI* (NSDictionary<NSString *, NSString *> *header) {
        self.header = header;
        return self;
    };
}


- (HLAPI* (^)(NSSet *contentTypes))setContentTypes {
    return ^HLAPI* (NSSet *contentTypes) {
        self.contentTypes = contentTypes;
        return self;
    };
}


- (HLAPI* (^)(NSString *customURL))setCustomURL {
    return ^HLAPI* (NSString *customURL) {
        self.cURL = customURL;
        return self;
    };
}

- (HLAPI *)progress:(void (^)(NSProgress * __nonnull))progress {
    [self setApiProgressHandler:^(NSProgress * __nonnull proc) {
        progress(proc);
    }];
    return self;
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
        hashStr = self.cURL;
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
    return [NSString stringWithFormat:@"\n===============HLAPI===============\nAPIVersion: %@\nClass: %@\nBaseURL: %@\nPath: %@\nCustomURL: %@\nParameters: %@\nHeader: %@\nContentTypes: %@\nTimeoutInterval: %f\nSecurityPolicy: %@\nRequestMethodType: %lu\nRequestSerializerType: %lu\nResponseSerializerType: %lu\nCachePolicy: %lu\n===============end===============\n\n", [HLAPIManager shared].config.apiVersion, self.class, self.baseURL ?: [HLAPIManager shared].config.baseURL, self.path, self.cURL ?: @"未设置", self.parameters, self.header, self.contentTypes, self.timeoutInterval, self.securityPolicy, self.apiRequestMethodType, self.apiRequestSerializerType, self.apiResponseSerializerType, self.cachePolicy];
}

- (NSString *)debugDescription {
    return self.description;
}

#pragma mark - getter / lazy load
- (NSString *)baseURL {
    return nil;
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

- (HLRequestMethodType)apiRequestMethodType {
    if (_requestMethodType) {
        return _requestMethodType;
    } else {
        return GET;
    }
}

- (HLRequestSerializerType)apiRequestSerializerType {
    if (_requestSerializerType) {
        return _requestSerializerType;
    } else {
        return RequestJSON;
    }
}

- (HLResponseSerializerType)apiResponseSerializerType {
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
        return @{@"Content-Type" : @"application/json; charset=utf-8"};
    }
}

- (NSSet *)contentTypes {
    if (_contentTypes) {
        return _contentTypes;
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
@end
