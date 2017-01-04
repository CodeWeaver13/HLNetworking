//
//  HLAPISyncBatchRequests.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/24.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLAPIChainRequests.h"
#import "HLAPI.h"
#import "HLAPIManager.h"

#define mix(A, B) A##B
// 创建任务队列
static dispatch_queue_t qkhl_api_chain_queue(const char * queueName) {
    static dispatch_queue_t mix(qkhl_api_chain_queue_, queueName);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mix(qkhl_api_chain_queue_, queueName) =
        dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL);
    });
    return mix(qkhl_api_chain_queue_, queueName);
}

static NSString * const hint = @"API 必须是 HLAPI的子类";
@interface HLAPIChainRequests ()

@property (nonatomic, strong, readwrite) NSMutableArray <HLAPI *>*apiRequestsArray;
@property (nonatomic, assign, readwrite)BOOL isCancel;
// 自定义的同步请求所在的串行队列
@property (nonatomic, strong, readwrite) dispatch_queue_t customChainQueue;
@end

@implementation HLAPIChainRequests
#pragma mark - Init
- (instancetype)init {
    self = [super init];
    if (self) {
        self.apiRequestsArray = [NSMutableArray array];
        self.isCancel = NO;
    }
    return self;
}

#pragma mark - NSFastEnumeration

- (NSUInteger)count {
    return _apiRequestsArray.count;
}

- (nonnull id)objectAtIndexedSubscript:(NSUInteger)idx {
    if (idx >= _apiRequestsArray.count) {
        [NSException raise:NSRangeException format:@"Index %lu 的区间为 [0, %lu].", (unsigned long)idx, (unsigned long)_apiRequestsArray.count];
    }
    return _apiRequestsArray[idx];
}

- (void)enumerateObjectsUsingBlock:(void (^)(HLAPI *api, NSUInteger idx, BOOL *stop))block {
    [_apiRequestsArray enumerateObjectsUsingBlock:block];
}

- (NSEnumerator*)objectEnumerator {
    return [_apiRequestsArray objectEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id  _Nullable __unsafe_unretained [])buffer
                                    count:(NSUInteger)len
{
    return [_apiRequestsArray countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Add Requests
- (void)add:(HLAPI *)api {
    NSParameterAssert(api);
    NSAssert([api isKindOfClass:[HLAPI class]], hint);
    if ([self.apiRequestsArray containsObject:api]) {
#ifdef DEBUG
        NSLog(@"批处理队列中已有相同的API！");
#endif
    }
    [self.apiRequestsArray addObject:api];
}

- (void)addAPIs:(nonnull NSArray<HLAPI *> *)apis {
    NSParameterAssert(apis);
    NSAssert([apis count] > 0, @"Api集合元素个数不可小于1");
    [apis enumerateObjectsUsingBlock:^(HLAPI * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self add:obj];
    }];
}

- (void)start {
    NSAssert([self.apiRequestsArray count] != 0, @"APIBatch元素不可小于1");
    [HLAPIManager sendChain:self];
    self.isCancel = NO;
}

- (void)cancel {
    NSAssert([self.apiRequestsArray count] != 0, @"APIBatch元素不可小于1");
    for (HLAPI *api in self.apiRequestsArray) {
        [HLAPIManager cancel:api];
    }
    self.isCancel = YES;
}

- (dispatch_queue_t)setupChainQueue:(NSString *)queueName {
    self.customChainQueue = qkhl_api_chain_queue([queueName UTF8String]);
    return self.customChainQueue;
}
@end
