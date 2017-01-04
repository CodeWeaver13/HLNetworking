//
//  HLAPIType.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#ifndef HLAPIType_h
#define HLAPIType_h
@protocol HLMultipartFormDataProtocol;
@class HLDebugMessage;
// 网络请求类型
typedef NS_ENUM(NSUInteger, HLRequestMethodType) {
    GET = 10,
    POST = 11,
    HEAD = 12,
    PUT = 13,
    PATCH = 14,
    DELETE = 15
};

// 请求的序列化格式
typedef NS_ENUM(NSUInteger, HLRequestSerializerType) {
    // Content-Type = application/x-www-form-urlencoded
    RequestHTTP = 100,
    // Content-Type = application/json
    RequestJSON = 101,
    // Content-Type = application/x-plist
    RequestPlist = 102
};

// 请求返回的序列化格式
typedef NS_ENUM(NSUInteger, HLResponseSerializerType) {
    // 默认的Response序列化方式（不处理）
    ResponseHTTP = 200,
    // 使用NSJSONSerialization解析Response Data
    ResponseJSON = 201,
    // 使用NSPropertyListSerialization解析Response Data
    ResponsePlist = 202,
    // 使用NSXMLParser解析Response Data
    ResponseXML = 203
};

// reachability的状态
typedef NS_ENUM(NSUInteger, HLReachabilityStatus) {
    HLReachabilityStatusUnknown,
    HLReachabilityStatusNotReachable,
    HLReachabilityStatusReachableViaWWAN,
    HLReachabilityStatusReachableViaWiFi
};

// 定义的Block
// 请求结果回调
typedef void(^HLSuccessBlock)(id __nullable responseObj);
// 请求失败回调
typedef void(^HLFailureBlock)(NSError * __nullable error);
// 请求进度回调
typedef void(^HLProgressBlock)(NSProgress * __nullable progress);
// formData拼接回调
typedef void(^HLRequestConstructingBodyBlock)(id<HLMultipartFormDataProtocol> __nullable formData);
// debug回调
typedef void(^HLDebugBlock)(HLDebugMessage * __nonnull debugMessage);



#endif /* HLAPIType_h */
