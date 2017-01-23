//
//  HLRequestGroup.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLRequestGroup.h"
#import "HLURLRequest.h"
#import "HLNetworkManager.h"

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

@interface HLRequestGroup ()
@property (nonatomic, strong, readwrite) NSMutableArray <__kindof HLURLRequest *>*apiArray;
// 自定义的同步请求所在的串行队列
@property (nonatomic, strong, readwrite) dispatch_queue_t customQueue;
@end
@implementation HLRequestGroup

#pragma mark - initialize method
- (instancetype)initWithMode:(HLRequestGroupMode)mode {
    self = [super init];
    if (self) {
        _apiArray = [NSMutableArray array];
        _groupMode = mode;
        _maxRequestCount = 1;
    }
    return self;
}
+ (instancetype)groupWithMode:(HLRequestGroupMode)mode {
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
- (void)enumerateObjectsUsingBlock:(void (^)(__kindof HLURLRequest *request, NSUInteger idx, BOOL *stop))block {
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
- (void)add:(__kindof HLURLRequest *)request {
    if (!request) {
        return;
    }
    if ([self.apiArray containsObject:request]) {
#ifdef DEBUG
        NSLog(@"批处理队列中已有相同的API！");
#endif
    }
    [self.apiArray addObject:request];
}
- (void)addRequests:(nonnull NSArray<__kindof HLURLRequest *> *)requests {
    if (!requests) return;
    if (requests.count == 0) return;
    [requests enumerateObjectsUsingBlock:^(HLURLRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self add:obj];
    }];
}
- (void)start {
    if (self.apiArray.count == 0) return;
    [HLNetworkManager sendGroup:self];
}
- (void)cancel {
    if (self.apiArray.count == 0) return;
    [HLNetworkManager cancelGroup:self];
}
- (dispatch_queue_t)setupGroupQueue:(NSString *)queueName {
    self.customQueue = qkhl_api_chain_queue([queueName UTF8String]);
    return self.customQueue;
}
@end
