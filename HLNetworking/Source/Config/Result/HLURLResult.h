//
//  HLURLResult.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger, HLURLResultStatus) {
    HLURLResultStatusSuccess, //作为底层，请求是否成功只考虑是否成功收到服务器反馈。至于签名是否正确，返回的数据是否完整，由上层的CTAPIBaseManager来决定。
    HLURLResultStatusErrorTimeout,
    HLURLResultStatusErrorNotReachable // 默认除了超时以外的错误都是无网络错误。
};

@interface HLURLResult : NSObject
@property (nonatomic, strong, readonly) id resultObject;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, assign, readonly) HLURLResultStatus status;

- (instancetype)initWithObject:(id)resultObject andError:(NSError *)error;
@end
