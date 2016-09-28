//
//  HLAPISyncBatchRequests.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/24.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLAPISyncBatchRequests.h"
#import "HLAPI.h"
#import "HLAPIManager.h"

static NSString * const hint = @"API 必须是 HLAPI的子类";
@interface HLAPISyncBatchRequests ()

@property (nonatomic, strong, readwrite) NSMutableArray *apiRequestsArray;
@property (nonatomic, assign, readwrite)BOOL isCancel;
@end

@implementation HLAPISyncBatchRequests
#pragma mark - Init
- (instancetype)init {
    self = [super init];
    if (self) {
        self.apiRequestsArray = [NSMutableArray array];
        self.isCancel = NO;
    }
    return self;
}

#pragma mark - Add Requests
- (void)addAPIRequest:(HLAPI *)api {
    NSParameterAssert(api);
    NSAssert([api isKindOfClass:[HLAPI class]], hint);
    if ([self.apiRequestsArray containsObject:api]) {
#ifdef DEBUG
        NSLog(@"批处理队列中已有相同的API！");
#endif
    }
    
    [self.apiRequestsArray addObject:api];
}

- (void)addBatchAPIRequests:(NSSet *)apis {
    NSParameterAssert(apis);
    NSAssert([apis count] > 0, @"Api集合元素个数不可小于1");
    [apis enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if ([obj isKindOfClass:[HLAPI class]]) {
            [self.apiRequestsArray addObject:obj];
        } else {
            __unused NSString *hintStr = [NSString stringWithFormat:@"%@ %@", [[obj class] description], hint];
            NSAssert(NO, hintStr);
            return ;
        }
    }];
}

- (void)start {
    NSAssert([self.apiRequestsArray count] != 0, @"APIBatch元素不可小于1");
    [[HLAPIManager shared] sendSyncBatchAPIRequests:self];
    self.isCancel = NO;
}

- (void)cancel {
    NSAssert([self.apiRequestsArray count] != 0, @"APIBatch元素不可小于1");
    for (HLAPI *api in self.apiRequestsArray) {
        [[HLAPIManager shared] cancelAPIRequest:api];
    }
    self.isCancel = YES;
}
@end
