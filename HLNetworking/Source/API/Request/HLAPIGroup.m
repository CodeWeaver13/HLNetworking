//
//  HLAPIGroup.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/7.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLAPIGroup.h"
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

@interface HLAPIGroup ()
@property (nonatomic, strong, readwrite) NSMutableArray <HLAPI *>*apiArray;
// 自定义的同步请求所在的串行队列
@property (nonatomic, strong, readwrite) dispatch_queue_t customChainQueue;
@end

@implementation HLAPIGroup
#pragma mark - Init
- (instancetype)initWithMode:(HLAPIGroupMode)mode {
    self = [super init];
    if (self) {
        _apiArray = [NSMutableArray array];
        _groupMode = mode;
        _maxRequestCount = 1;
    }
    return self;
}

+ (instancetype)groupWithMode:(HLAPIGroupMode)mode {
    return [[self alloc] initWithMode:mode];
}

#pragma mark - NSFastEnumeration

- (NSUInteger)count {
    return _apiArray.count;
}

- (nonnull id)objectAtIndexedSubscript:(NSUInteger)idx {
    if (idx >= _apiArray.count) {
        [NSException raise:NSRangeException format:@"Index %lu 的区间为 [0, %lu].", (unsigned long)idx, (unsigned long)_apiArray.count];
    }
    return _apiArray[idx];
}

- (void)enumerateObjectsUsingBlock:(void (^)(HLAPI *api, NSUInteger idx, BOOL *stop))block {
    [_apiArray enumerateObjectsUsingBlock:block];
}

- (NSEnumerator*)objectEnumerator {
    return [_apiArray objectEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id  _Nullable __unsafe_unretained [])buffer
                                    count:(NSUInteger)len
{
    return [_apiArray countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Add Requests
- (void)add:(HLAPI *)api {
    NSParameterAssert(api);
    NSAssert([api isKindOfClass:[HLAPI class]], hint);
    if ([self.apiArray containsObject:api]) {
#ifdef DEBUG
        NSLog(@"批处理队列中已有相同的API！");
#endif
    }
    [self.apiArray addObject:api];
}

- (void)addAPIs:(nonnull NSArray<HLAPI *> *)apis {
    NSParameterAssert(apis);
    NSAssert([apis count] > 0, @"Api集合元素个数不可小于1");
    [apis enumerateObjectsUsingBlock:^(HLAPI * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self add:obj];
    }];
}

- (void)start {
    NSAssert([self.apiArray count] != 0, @"APIBatch元素不可小于1");
    [HLAPIManager sendGroup:self];
}

- (void)cancel {
    NSAssert([self.apiArray count] != 0, @"APIBatch元素不可小于1");
    [HLAPIManager cancelGroup:self];
}

- (dispatch_queue_t)setupGroupQueue:(NSString *)queueName {
    self.customChainQueue = qkhl_api_chain_queue([queueName UTF8String]);
    return self.customChainQueue;
}
@end
