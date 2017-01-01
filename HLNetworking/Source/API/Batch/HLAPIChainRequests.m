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

@interface HLAPIChainRequestsEnumerator : NSEnumerator
{
    HLAPIChainRequests *_enumerableClassInstanceToEnumerate;
    NSUInteger _currentIndex;
}
- (id)initWithEnumerableClass:(HLAPIChainRequests *)anEnumerableClass;
@end


@implementation HLAPIChainRequestsEnumerator

- (id)initWithEnumerableClass:(HLAPIChainRequests *)anEnumerableClass {
    self = [super init];
    if (self) {
        _enumerableClassInstanceToEnumerate = anEnumerableClass;
        _currentIndex = 0;
    }
    return self;
}

- (id)nextObject {
    if (_currentIndex >= _enumerableClassInstanceToEnumerate.count)
        return nil;
    
    return _enumerableClassInstanceToEnumerate[_currentIndex++];
}
@end

static NSString * const hint = @"API 必须是 HLAPI的子类";
@interface HLAPIChainRequests ()

@property (nonatomic, strong, readwrite) NSMutableArray *apiRequestsArray;
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

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block {
    [_apiRequestsArray enumerateObjectsUsingBlock:block];
}

- (NSEnumerator*)objectEnumerator {
    return [[HLAPIChainRequestsEnumerator alloc] initWithEnumerableClass:self];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)stackbufLength {
    NSUInteger count = 0;
    
    unsigned long countOfItemsAlreadyEnumerated = state->state;
    
    if(countOfItemsAlreadyEnumerated == 0) {
        state->mutationsPtr = &state->extra[0];
    }
    
    if(countOfItemsAlreadyEnumerated < _apiRequestsArray.count) {
        state->itemsPtr = stackbuf;
        while((countOfItemsAlreadyEnumerated < _apiRequestsArray.count) && (count < stackbufLength)) {
            stackbuf[count] = _apiRequestsArray[countOfItemsAlreadyEnumerated];
            countOfItemsAlreadyEnumerated++;
            
            count++;
        }
    } else {
        count = 0;
    }
    
    state->state = countOfItemsAlreadyEnumerated;
    
    return count;
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
