//
//  HLURLResponse.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLURLResponse.h"

@interface HLURLResponse ()

@property (nonatomic, assign, readwrite) HLURLResponseStatus status;
@property (nonatomic, strong, readwrite) HLURLResult *result;
@property (nonatomic, copy, readwrite) NSURLRequest *request;
@property (nonatomic, assign, readwrite) NSInteger requestId;
@property (nonatomic, copy, readwrite) NSDictionary *requestParams;

@end

@implementation HLURLResponse

#pragma mark - life cycle
- (instancetype)initWithResult:(HLURLResult *)result
                     requestId:(NSNumber *)requestId
                       request:(NSURLRequest *)request
                 requestPrarms:(NSDictionary *)params
                        status:(HLURLResponseStatus)status
{
    self = [super init];
    if (self) {
        _result = result;
        _status = status;
        self.requestId = [requestId integerValue];
        self.request = request;
        self.requestParams = params;
    }
    return self;
}

- (instancetype)initWithResponseResult:(HLURLResult *)result
                             requestId:(NSNumber *)requestId
                               request:(NSURLRequest *)request
                         requestPrarms:(NSDictionary *)params
                                 error:(NSError *)error
{
    self = [super init];
    if (self) {
        self.status = [self responseStatusWithError:error];
        self.requestId = [requestId integerValue];
        self.request = request;
        self.requestParams = params;
    }
    return self;
}

#pragma mark - private methods
- (HLURLResponseStatus)responseStatusWithError:(NSError *)error
{
    if (error) {
        HLURLResponseStatus result = HLURLResponseStatusErrorNoNetwork;
        
        // 除了超时以外，所有错误都当成是无网络
        if (error.code == NSURLErrorTimedOut) {
            result = HLURLResponseStatusErrorNoNetwork;
        }
        return result;
    } else {
        return HLURLResponseStatusSuccess;
    }
}
@end
