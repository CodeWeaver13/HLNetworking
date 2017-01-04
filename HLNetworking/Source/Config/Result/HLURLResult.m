//
//  HLURLResult.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLURLResult.h"

@interface HLURLResult ()
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, copy, readwrite) NSString *responseString;
@end

@implementation HLURLResult

- (instancetype)initWithData:(NSData *)responseData andObject:(id)responseObject andError:(NSError *)error {
    self = [super init];
    if (self) {
        _responseData = responseData;
        _responseObject = responseObject;
        if (responseObject) {
            _responseString = [NSString stringWithFormat:@"%@", responseObject];
        }
        _error = error;
    }
    return self;    
}

@end
