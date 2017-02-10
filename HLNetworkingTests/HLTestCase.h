//
//  HLTestCase.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/2/9.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HLNetworking.h"

@interface HLTestCase : XCTestCase<HLNetworkCustomLoggerDelegate>

@property (nonatomic, assign) NSTimeInterval networkTimeout;

- (void)waitForExpectationsWithCommonTimeout;
- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler;

@end
