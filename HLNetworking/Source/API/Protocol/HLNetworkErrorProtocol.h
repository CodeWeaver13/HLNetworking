//
//  HLNetworkErrorProtocol.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HLNetworkErrorProtocol <NSObject>
/**
 *  发生HTTP层网络错误时，通过该函数进行监控回调
 *
 *  @param error 网络错误的Error
 */
- (void)networkErrorInfo:(nonnull NSError *)error;
@end
