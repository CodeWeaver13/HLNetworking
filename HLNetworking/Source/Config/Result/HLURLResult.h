//
//  HLURLResult.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/4.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLURLResult : NSObject
@property (nonatomic, strong, readonly) id responseObject;
@property (nonatomic, strong, readonly) NSData *responseData;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, copy, readonly) NSString *responseString;

- (instancetype)initWithData:(NSData *)responseData andObject:(id)responseObject andError:(NSError *)error;
@end
