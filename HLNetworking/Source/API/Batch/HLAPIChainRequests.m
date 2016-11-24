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

- (NSUInteger)numItems {
    return _apiRequestsArray.count;
}

- (nonnull id)objectAtIndexedSubscript:(NSUInteger)idx {
    if (idx >= _apiRequestsArray.count) {
        [NSException raise:NSRangeException format:@"Index %li is beyond bounds [0, %li].", (unsigned long)idx, _apiRequestsArray.count];
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

- (void)addChainAPIRequests:(nonnull NSArray<HLAPI *> *)apis {
    NSParameterAssert(apis);
    NSAssert([apis count] > 0, @"Api集合元素个数不可小于1");
    [apis enumerateObjectsUsingBlock:^(HLAPI * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addAPIRequest:obj];
    }];
}

- (void)start {
    NSAssert([self.apiRequestsArray count] != 0, @"APIBatch元素不可小于1");
    [[HLAPIManager shared] sendChainAPIRequests:self];
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
