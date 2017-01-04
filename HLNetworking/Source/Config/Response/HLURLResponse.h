//
//  HLURLResponse.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLURLResult.h"

@interface HLURLResponse : NSObject
@property (nonatomic, strong, readonly) HLURLResult *result;
@property (nonatomic, assign, readonly) NSInteger requestId;
@property (nonatomic, copy, readonly) NSURLRequest *request;

- (instancetype)initWithResult:(HLURLResult *)result
                     requestId:(NSNumber *)requestId
                       request:(NSURLRequest *)request;
@end
