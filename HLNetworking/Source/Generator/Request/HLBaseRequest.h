//
//  HLBaseRequest.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/8.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HLBaseRequest;
NS_ASSUME_NONNULL_BEGIN
#pragma mark - HLAPIRequestDelegate
@protocol HLRequestDelegate <NSObject>

@optional
// 请求将要发出
- (void)requestWillBeSentWithRequest:(HLBaseRequest *)request;
// 请求已经发出
- (void)requestDidSentWithRequest:(HLBaseRequest *)request;
@end

@interface HLBaseRequest : NSObject

@property (nonatomic, copy, readonly) NSString *baseURL;
@property (nonatomic, copy, readonly) NSString *path;
@end

NS_ASSUME_NONNULL_END
