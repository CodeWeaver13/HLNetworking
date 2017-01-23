//
//  HLFormDataConfig.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/23.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import "HLFormDataConfig.h"

@implementation HLFormDataConfig
+ (void (^)(id<HLMultipartFormDataProtocol>))configWithData:(NSData *)data
                                                       name:(NSString *)name
                                                   fileName:(NSString *)fileName
                                                   mimeType:(NSString *)mimeType
{
    return ^(id<HLMultipartFormDataProtocol> formData) {
        [formData appendPartWithFileData:data
                                    name:name
                                fileName:fileName
                                mimeType:mimeType];
    };
}

+ (void (^)(id<HLMultipartFormDataProtocol>))configWithImage:(UIImage *)image
                                                        name:(NSString *)name
                                                    fileName:(NSString *)fileName
                                                       scale:(CGFloat)scale
{
    return ^(id<HLMultipartFormDataProtocol> formData) {
        NSData *data;
        NSString *mimeType;
        if (UIImagePNGRepresentation(image) == nil) {
            data = UIImageJPEGRepresentation(image, scale);
            mimeType = @"JPEG";
        }else {
            data = UIImagePNGRepresentation(image);
            mimeType = @"PNG";
        }
        [formData appendPartWithFileData:data
                                    name:name
                                fileName:fileName
                                mimeType:mimeType];
    };
}
@end
