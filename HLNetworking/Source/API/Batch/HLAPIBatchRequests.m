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
@property (nonatomic, strong, readwrite) NSMutableSet<HLAPI *> *apiSet;

@end

@implementation HLAPIBatchRequests

#pragma mark - Init
- (instancetype)init {
    self = [super init];
    if (self) {
        _apiSet = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Add Requests
- (void)add:(HLAPI *)api {
    NSParameterAssert(api);
    NSAssert([api isKindOfClass:[HLAPI class]], hint);
    if ([self.apiSet containsObject:api]) {
#ifdef DEBUG
        NSLog(@"批处理队列中已有相同的API！");
#endif
    }
    
    [self.apiSet addObject:api];
}

- (void)addAPIs:(NSSet<HLAPI *> *)apis {
    NSParameterAssert(apis);
    NSAssert([apis count] > 0, @"Api集合元素个数不可小于1");
    [apis enumerateObjectsUsingBlock:^(HLAPI * _Nonnull obj, BOOL * _Nonnull stop) {
        [self add:obj];
    }];
}

- (void)start {
    NSAssert([self.apiSet count] != 0, @"APIBatch元素不可小于1");
    [HLAPIManager sendBatch:self];
}

- (void)cancel {
    NSAssert([self.apiSet count] != 0, @"APIBatch元素不可小于1");
    for (HLAPI *api in self.apiSet) {
        [HLAPIManager cancel:api];
    }
    self.isCancel = YES;
}
@end
