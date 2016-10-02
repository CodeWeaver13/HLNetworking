//
//  HLAPIRequestDelegate.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/10/2.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HLAPIRequestDelegate <NSObject>
@optional
// 请求将要发出
- (void)requestWillBeSentWithAPI:(HLAPI *)api;
// 请求已经发出
- (void)requestDidSentWithAPI:(HLAPI *)api;
@end
