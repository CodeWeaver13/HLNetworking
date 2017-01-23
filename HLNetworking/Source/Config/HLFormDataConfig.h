//
//  HLFormDataConfig.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/23.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
#pragma mark - 用于拼接formData的协议
@protocol HLMultipartFormDataProtocol
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __nullable __autoreleasing *)error;
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * __nullable __autoreleasing *)error;
- (void)appendPartWithInputStream:(nullable NSInputStream *)inputStream
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                         mimeType:(NSString *)mimeType;
- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType;
- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name;
- (void)appendPartWithHeaders:(nullable NSDictionary *)headers
                         body:(NSData *)body;
- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay;
@end

@interface HLFormDataConfig : NSObject
// 用于二进制数据的formData拼接
+ (void (^)(id<HLMultipartFormDataProtocol>))configWithData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;
// 用于图片数据的formData拼接
+ (void (^)(id<HLMultipartFormDataProtocol>))configWithImage:(UIImage *)image name:(NSString *)name fileName:(NSString *)fileName scale:(CGFloat)scale;
@end
NS_ASSUME_NONNULL_END
