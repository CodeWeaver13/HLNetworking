//
//  HLNetworkConfig.h
//  HLPPShop
//
//  Created by wangshiyu13 on 2016/9/19.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *HLDefaultGeneralErrorString;
FOUNDATION_EXPORT NSString *HLDefaultFrequentRequestErrorString;
FOUNDATION_EXPORT NSString *HLDefaultNetworkNotReachableString;

@interface HLNetworkConfig : NSObject<NSCopying>

@property (nonatomic, strong) NSDictionary *defaultParams;

/**
 是否为后台模式所用的GroupID，该选项只对Task有影响
 */
@property (nonatomic, copy) NSString *AppGroup;
/**
 是否为后台模式，该选项只对Task有影响
 */
@property (nonatomic, assign) BOOL isBackgroundSession;
/**
 *  出现网络请求时，为了给用户比较好的用户体验，而使用的错误提示文字
 *  默认为：HLDefaultGeneralErrorString
 */
@property (nonatomic, copy) NSString *generalErrorTypeStr;

/**
 *  用户频繁发送同一个请求，使用的错误提示文字
 *  默认为：HLDefaultFrequentRequestErrorString
 */
@property (nonatomic, copy) NSString *frequentRequestErrorStr;

/**
 *  网络请求开始时，会先检测相应网络域名的Reachability，如果不可达，则直接返回该错误文字
 *  默认为：HLDefaultNetworkNotReachableString
 */
@property (nonatomic, copy) NSString *networkNotReachableErrorStr;

/**
 *  出现网络请求错误时，是否在请求错误的文字后加上(code)
 *  默认为：YES
 */
@property (nonatomic, assign) BOOL isErrorCodeDisplayEnabled;

/**
 *  修改的baseURL
 */
@property (nonatomic, copy, nullable) NSString *baseURL;

/**
 *  api版本
 */
@property (nonatomic, copy, nullable) NSString *apiVersion;


/**
 是否为审核版本
 */
@property (nonatomic, assign) BOOL isJudgeVersion;
/**
 *  UserAgent
 */
@property (nonatomic, copy, nullable) NSString *userAgent;

/**
 *  每个Host的最大连接数
 *  默认为2
 */
@property (nonatomic, assign) NSUInteger maxHttpConnectionPerHost;

/**
 *  NetworkingActivityIndicator
 *  Default by YES
 */
@property (nonatomic, assign) BOOL isNetworkingActivityIndicatorEnabled;


+ (HLNetworkConfig *)config;

@end

NS_ASSUME_NONNULL_END
