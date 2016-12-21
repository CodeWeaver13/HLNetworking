//
//  HLSecurityPolicyConfig.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLAPIType.h"

@interface HLSecurityPolicyConfig : NSObject
/**
 *  SSL Pinning证书的校验模式
 *  默认为 HLSSLPinningModeNone
 */
@property (readonly, nonatomic, assign) HLSSLPinningMode SSLPinningMode;

/**
 *  是否允许使用Invalid 证书
 *  默认为 NO
 */
@property (nonatomic, assign) BOOL allowInvalidCertificates;

/**
 *  是否校验在证书 CN 字段中的 domain name
 *  默认为 YES
 */
@property (nonatomic, assign) BOOL validatesDomainName;


/**
 cer证书文件路径
 */
@property (nonatomic, copy) NSString *cerFilePath;

/**
 *  创建新的SecurityPolicy
 *
 *  @param pinningMode 证书校验模式
 *
 *  @return 新的SecurityPolicy
 */
+ (instancetype)policyWithPinningMode:(HLSSLPinningMode)pinningMode;
@end
