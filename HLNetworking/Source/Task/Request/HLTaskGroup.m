//
//  HLTaskGroup.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/7.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLTaskGroup.h"
#import "HLTaskManager.h"

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

@interface HLTaskGroup ()
@property (nonatomic, strong, readwrite) NSMutableArray <HLTask *>*taskArray;
// 自定义的同步请求所在的串行队列
@property (nonatomic, strong, readwrite) dispatch_queue_t customQueue;
@end
@implementation HLTaskGroup
#pragma mark - Init
- (instancetype)initWithMode:(HLAPIGroupMode)mode {
    self = [super init];
    if (self) {
        _taskArray = [NSMutableArray array];
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
    return _taskArray.count;
}

- (nonnull id)objectAtIndexedSubscript:(NSUInteger)idx {
    if (idx >= _taskArray.count) {
        [NSException raise:NSRangeException format:@"Index %lu 的区间为 [0, %lu].", (unsigned long)idx, (unsigned long)_taskArray.count];
    }
    return _taskArray[idx];
}

- (void)enumerateObjectsUsingBlock:(void (^)(HLTask *api, NSUInteger idx, BOOL *stop))block {
    [_taskArray enumerateObjectsUsingBlock:block];
}

- (NSEnumerator*)objectEnumerator {
    return [_taskArray objectEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id  _Nullable __unsafe_unretained [])buffer
                                    count:(NSUInteger)len
{
    return [_taskArray countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Add Requests
- (void)add:(HLTask *)task {
    if (!task) {
        return;
    }
    if ([self.taskArray containsObject:task]) {
#ifdef DEBUG
        NSLog(@"批处理队列中已有相同的API！");
#endif
    }
    [self.taskArray addObject:task];
}

- (void)addAPIs:(nonnull NSArray<HLTask *> *)tasks {
    if (!tasks) return;
    if (tasks.count == 0) return;
    [tasks enumerateObjectsUsingBlock:^(HLTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self add:obj];
    }];
}

- (void)start {
    if (self.taskArray.count == 0) return;
    [HLTaskManager sendGroup:self];
}

- (void)cancel {
    if (self.taskArray.count == 0) return;
    [HLTaskManager cancelGroup:self];
}

- (dispatch_queue_t)setupGroupQueue:(NSString *)queueName {
    self.customQueue = qkhl_api_chain_queue([queueName UTF8String]);
    return self.customQueue;
}
@end
