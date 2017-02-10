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
                                                     quality:(CGFloat)quality
{
    return ^(id<HLMultipartFormDataProtocol> formData) {
        NSData *data;
        NSString *mimeType;
        if (UIImagePNGRepresentation(image) == nil) {
            data = UIImageJPEGRepresentation(image, quality);
            mimeType = @"image/jpeg";
        }else {
            data = UIImagePNGRepresentation(image);
            mimeType = @"image/png";
        }
        [formData appendPartWithFileData:data
                                    name:name
                                fileName:fileName
                                mimeType:mimeType];
    };
}

+ (void (^)(id<HLMultipartFormDataProtocol>))configWithFileURL:(NSURL *)fileURL
                                                          name:(NSString *)name
                                                      fileName:(NSString *)fileName
                                                      mimeType:(NSString *)mimeType
                                                         error:(NSError * __nullable __autoreleasing *)error
{
    return ^(id<HLMultipartFormDataProtocol> formData) {
        [formData appendPartWithFileURL:fileURL
                                   name:name
                               fileName:fileName
                               mimeType:mimeType
                                  error:error];
    };
}

+ (void (^)(id<HLMultipartFormDataProtocol>))configWithInputStream:(nullable NSInputStream *)inputStream
                                                              name:(NSString *)name
                                                          fileName:(NSString *)fileName
                                                            length:(int64_t)length
                                                          mimeType:(NSString *)mimeType {
    return ^(id<HLMultipartFormDataProtocol> formData) {
        [formData appendPartWithInputStream:inputStream
                                       name:name
                                   fileName:fileName
                                     length:length
                                   mimeType:mimeType];
    };
}
@end
