//
//  HLURLResponse.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLURLResult.h"

typedef NS_ENUM(NSUInteger, HLURLResponseStatus)
{
    HLURLResponseStatusSuccess, //作为底层，请求是否成功只考虑是否成功收到服务器反馈。至于签名是否正确，返回的数据是否完整，由上层的CTAPIBaseManager来决定。
    HLURLResponseStatusErrorTimeout,
    HLURLResponseStatusErrorNoNetwork // 默认除了超时以外的错误都是无网络错误。
};

@interface HLURLResponse : NSObject
@property (nonatomic, assign, readonly) HLURLResponseStatus status;
@property (nonatomic, strong, readonly) HLURLResult *result;
@property (nonatomic, assign, readonly) NSInteger requestId;
@property (nonatomic, copy, readonly) NSURLRequest *request;
@property (nonatomic, copy, readonly) NSDictionary *requestParams;

- (instancetype)initWithResult:(HLURLResult *)result
                     requestId:(NSNumber *)requestId
                       request:(NSURLRequest *)request
                 requestPrarms:(NSDictionary *)params
                        status:(HLURLResponseStatus)status;

- (instancetype)initWithResponseResult:(HLURLResult *)result
                             requestId:(NSNumber *)requestId
                               request:(NSURLRequest *)request
                         requestPrarms:(NSDictionary *)params
                                 error:(NSError *)error;

@end
