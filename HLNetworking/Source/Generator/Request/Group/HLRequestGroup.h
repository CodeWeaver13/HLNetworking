//
//  HLRequestGroup.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HLURLRequest;
@class HLRequestGroup;

typedef NS_ENUM(NSUInteger, HLRequestGroupMode) {
    HLRequestGroupModeBatch,
    HLRequestGroupModeChian
};

NS_ASSUME_NONNULL_BEGIN
@protocol HLRequestGroupDelegate <NSObject>
// Requests 全部调用完成之后调用
- (void)requestGroupAllDidFinished:(nonnull __kindof HLRequestGroup *)apiGroup;
@end

@interface HLRequestGroup : NSObject
// 请求组类型
@property (nonatomic, assign, readonly) HLRequestGroupMode groupMode;

@property (nonatomic, assign) NSUInteger maxRequestCount;

// 自定义的同步请求所在的串行队列
@property (nonatomic, strong, readonly) dispatch_queue_t customQueue;

// Group 内 api 执行完成之后调用的delegate
@property (nonatomic, weak, nullable) id<HLRequestGroupDelegate> delegate;

// 请使用manager或sharedManager
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// 返回一个新的manager对象
+ (instancetype)groupWithMode:(HLRequestGroupMode)mode;

// 加入到group集合中
- (void)add:(nonnull __kindof HLURLRequest *)request;

// 将带有API集合的Array 赋值
- (void)addRequests:(nonnull NSArray<__kindof HLURLRequest *> *)requests;

// 开启队列请求
- (void)start;

// 取消所有请求
- (void)cancel;

// 设置组GCD队列
- (dispatch_queue_t)setupGroupQueue:(NSString *)queueName;

#pragma mark - 遍历方法

@property (readonly) NSUInteger count;

- (void)enumerateObjectsUsingBlock:(void (^)(__kindof HLURLRequest *request, NSUInteger idx, BOOL * stop))block;

- (nonnull NSEnumerator*)objectEnumerator;

- (nonnull id)objectAtIndexedSubscript:(NSUInteger)idx;
@end
NS_ASSUME_NONNULL_END
