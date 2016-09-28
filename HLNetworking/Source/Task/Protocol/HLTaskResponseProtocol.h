//
//  HLTaskResponseProtocol.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/29.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HLTaskResponseProtocol <NSObject>
    @required
- (NSArray <HLTask *>* _Nonnull)requestTasks;
    
    @optional
    /**
     *  task 上传、下载等长时间执行的Progress进度
     *  NSProgress: 进度
     */
- (void)requestProgress:(nullable NSProgress *)progress atTask:(nullable HLTask *)task;
    
    /**
     请求成功的回调
     
     @param responseObject 回调对象
     */
- (void)requestSucessWithResponseObject:(nonnull id)responseObject atTask:(nullable HLTask *)task;
    
    /**
     请求失败的回调
     
     @param error 错误对象
     */
- (void)requestFailureWithResponseError:(nullable NSError *)error atTask:(nullable HLTask *)task;

@end
