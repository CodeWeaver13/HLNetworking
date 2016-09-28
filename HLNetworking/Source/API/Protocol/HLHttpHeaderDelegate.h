//
//  HLHttpHeaderDelegate.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HLHttpHeaderDelegate <NSObject>

- (nullable NSDictionary *)apiRequestHTTPHeaderField;

@end

NS_ASSUME_NONNULL_END
