//
//  HLAPIBatchRequests.m
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLAPIBatchRequests.h"
#import "HLAPIManager.h"
#import "HLAPI.h"

static NSString * const hint = @"API 必须是 HLAPI的子类";

@interface HLAPIBatchRequests ()

@property (nonatomic, strong, readwrite) NSMutableSet *apiRequestsSet;

@end

@implementation HLAPIBatchRequests

#pragma mark - Init
- (instancetype)init {
    self = [super init];
    if (self) {
        self.apiRequestsSet = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Add Requests
- (void)addAPIRequest:(HLAPI *)api {
    NSParameterAssert(api);
    NSAssert([api isKindOfClass:[HLAPI class]], hint);
    if ([self.apiRequestsSet containsObject:api]) {
#ifdef DEBUG
        NSLog(@"批处理队列中已有相同的API！");
#endif
    }
    
    [self.apiRequestsSet addObject:api];
}

- (void)addBatchAPIRequests:(NSSet *)apis {
    NSParameterAssert(apis);
    NSAssert([apis count] > 0, @"Api集合元素个数不可小于1");
    [apis enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if ([obj isKindOfClass:[HLAPI class]]) {
            [self.apiRequestsSet addObject:obj];
        } else {
            __unused NSString *hintStr = [NSString stringWithFormat:@"%@ %@", [[obj class] description], hint];
            NSAssert(NO, hintStr);
            return ;
        }
    }];
}

- (void)start {
    NSAssert([self.apiRequestsSet count] != 0, @"APIBatch元素不可小于1");
    [[HLAPIManager shared] sendBatchAPIRequests:self];
}

@end
