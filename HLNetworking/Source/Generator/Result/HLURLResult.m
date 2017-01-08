//
//  HLURLResult.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLURLResult.h"

@interface HLURLResult ()
@property (nonatomic, strong, readwrite) id resultObject;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, assign, readwrite) HLURLResultStatus status;
@end

@implementation HLURLResult

- (instancetype)initWithObject:(id)resultObject andError:(NSError *)error {
    self = [super init];
    if (self) {
        _resultObject = resultObject;
        _error = error;
        _status = [self resultStatusWithError:error];
    }
    return self;    
}

- (HLURLResultStatus)resultStatusWithError:(NSError *)error {
    if (error) {
        HLURLResultStatus result = HLURLResultStatusErrorNotReachable;
        
        // 除了超时以外，所有错误都当成是无网络
        if (error.code == NSURLErrorTimedOut) {
            result = HLURLResultStatusErrorTimeout;
        }
        return result;
    } else {
        return HLURLResultStatusSuccess;
    }
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"\n---------HLURLResult Start---------\n"];
    [desc appendFormat:@"Status : %@\n", [self getHLURLResultStatusString:self.status]];
    [desc appendFormat:@"Object : %@\n", self.resultObject];
    [desc appendFormat:@"Error : %@\n", self.error ?: @"成功"];
    [desc appendString:@"----------HLURLResult End----------"];
    return desc;
}

- (NSString *)debugDescription {
    return self.description;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"Status"] = [self getHLURLResultStatusString:self.status];
    dict[@"Object"] = [NSString stringWithFormat:@"%@", [self.resultObject class]];
    dict[@"Error"] = self.error.localizedDescription ?: @"无错误";
    return dict;
}

- (NSString *)getHLURLResultStatusString:(HLURLResultStatus)status {
    switch (status) {
        case HLURLResultStatusSuccess:
            return @"HLURLResultStatusSuccess";
            break;
        case HLURLResultStatusErrorTimeout:
            return @"HLURLResultStatusErrorTimeout";
            break;
        case HLURLResultStatusErrorNotReachable:
            return @"HLURLResultStatusErrorNotReachable";
            break;
        default:
            return @"HLURLResultStatusErrorUnknown";
            break;
    }
}

@end
