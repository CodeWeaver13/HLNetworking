//
//  HLAPIResponseDelegate.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/10/2.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HLAPI;

NS_ASSUME_NONNULL_BEGIN
@protocol HLAPIResponseDelegate <NSObject>
@required
- (NSArray <HLAPI *>*)requestAPIs;

@optional

/**
 请求成功的回调
 
 @param responseObject 回调对象
 */
- (void)requestSucessWithResponseObject:(nonnull id)responseObject atAPI:(HLAPI *)api;

/**
 请求失败的回调
 
 @param error 错误对象
 */
- (void)requestFailureWithResponseError:(nullable NSError *)error atAPI:(HLAPI *)api;

/**
 *  api 上传、下载等长时间执行的Progress进度
 *  NSProgress: 进度
 */
- (void)requestProgress:(nullable NSProgress *)progress atAPI:(HLAPI *)api;
@end
NS_ASSUME_NONNULL_END
