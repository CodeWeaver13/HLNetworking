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

@property (nonatomic, assign, readwrite) BOOL isCancel;
@property (nonatomic, strong, readwrite) NSMutableSet<HLAPI *> *apiRequestsSet;

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

- (void)addBatchAPIRequests:(NSSet<HLAPI *> *)apis {
    NSParameterAssert(apis);
    NSAssert([apis count] > 0, @"Api集合元素个数不可小于1");
    [apis enumerateObjectsUsingBlock:^(HLAPI * _Nonnull obj, BOOL * _Nonnull stop) {
        [self addAPIRequest:obj];
    }];
}

- (void)start {
    NSAssert([self.apiRequestsSet count] != 0, @"APIBatch元素不可小于1");
    [[HLAPIManager shared] sendBatchAPIRequests:self];
}

- (void)cancel {
    NSAssert([self.apiRequestsSet count] != 0, @"APIBatch元素不可小于1");
    for (HLAPI *api in self.apiRequestsSet) {
        [[HLAPIManager shared] cancelAPIRequest:api];
    }
    self.isCancel = YES;
}
@end
