//
//  NSNull+ToDictionary.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "NSNull+ToDictionary.h"

@implementation NSNull (ToDictionary)
- (NSDictionary *)toDictionary {
    return @{@"NSNull": @"null"};
}
@end
