//
//  HLFormDataConfig.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/23.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol HLMultipartFormDataProtocol;

@interface HLFormDataConfig : NSObject
+ (void (^)(id<HLMultipartFormDataProtocol>))configWithData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;
+ (void (^)(id<HLMultipartFormDataProtocol>))configWithImage:(UIImage *)image name:(NSString *)name fileName:(NSString *)fileName scale:(CGFloat)scale;
@end
