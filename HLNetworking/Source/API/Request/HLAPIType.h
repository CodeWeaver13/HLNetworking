//
//  HLAPIType.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#ifndef HLAPIType_h
#define HLAPIType_h

// 网络请求类型
typedef NS_ENUM(NSUInteger, HLRequestMethodType) {
    GET = 0,
    POST = 1,
    HEAD = 2,
    PUT = 3,
    PATCH = 4,
    DELETE = 5
};

// 请求的序列化格式
typedef NS_ENUM(NSUInteger, HLRequestSerializerType) {
    RequestHTTP = 0,
    RequestJSON = 1
};

// 请求返回的序列化格式
typedef NS_ENUM(NSUInteger, HLResponseSerializerType) {
    ResponseHTTP = 0,
    ResponseJSON = 1
};

/**
 *  SSL Pinning
 */
typedef NS_ENUM(NSUInteger, HLSSLPinningMode) {
    /**
     *  不校验Pinning证书
     */
    None,
    /**
     *  校验Pinning证书中的PublicKey.
     */
    PublicKey,
    /**
     *  校验整个Pinning证书
     */
    Certificate
};

// 默认的请求超时时间
#define HL_API_REQUEST_TIME_OUT     15

// 每个host最大连接数
#define MAX_HTTP_CONNECTION_PER_HOST 5

#endif /* HLAPIType_h */
