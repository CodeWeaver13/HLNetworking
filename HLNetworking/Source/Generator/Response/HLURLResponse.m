//
//  HLURLResponse.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLURLResponse.h"

@interface HLURLResponse ()

@property (nonatomic, strong, readwrite) HLURLResult *result;
@property (nonatomic, copy, readwrite) NSURLRequest *request;
@property (nonatomic, assign, readwrite) NSUInteger requestId;

@end

@implementation HLURLResponse

#pragma mark - life cycle
- (instancetype)initWithResult:(HLURLResult *)result
                     requestId:(NSNumber *)requestId
                       request:(NSURLRequest *)request
{
    self = [super init];
    if (self) {
        _result = result;
        _requestId = [requestId integerValue];
        _request = request;
    }
    return self;
}

#pragma mark - private methods


- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"\n++++++++HLURLResponse Start++++++++\n"];
    [desc appendFormat:@"Result : %@\n", self.result];
    [desc appendFormat:@"Request : %@\n", self.request];
    [desc appendFormat:@"RequestId : %lu\n", (unsigned long)self.requestId];
    [desc appendString:@"+++++++++HLURLResponse End+++++++++\n"];
    return desc;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"Result"] = [self.result toDictionary];
    dict[@"Request"] = self.request.description;
    dict[@"RequestId"] = [NSString stringWithFormat:@"%lu", (unsigned long)self.requestId];
    return dict;
}

- (NSString *)debugDescription {
    return self.description;
}

@end
