//
//  HLManagerTests.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/2/9.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLTestCase.h"

@interface HLManagerTests : HLTestCase
@property (nonatomic, strong) HLNetworkManager *testManager2;
@end

@implementation HLManagerTests

- (void)setUp {
    [super setUp];
    self.testManager2 = [HLNetworkManager manager];
}

- (void)tearDown {
    [super tearDown];
    self.testManager2 = nil;
}

- (void)testCallbackQueue {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"The callback blocks should be called in main thread."];
    
    [HLNetworkManager send:[HLAPIRequest request]
     .setMethod(GET)
     .setCustomURL(@"https://httpbin.org/get")
     .success(^(id result){
        XCTAssertNotNil(result);
        XCTAssertTrue([NSThread isMainThread]);
        [expectation1 fulfill];
    })
     .failure(^(NSError *error){
        XCTAssertNil(error);
    })];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"The callback blocks should be called in a private thread."];
    [self.testManager2 setupConfig:^(HLNetworkConfig * _Nonnull config) {
        config.request.callbackQueue = dispatch_get_global_queue(0, 0);
        config.request.apiVersion = nil;
    }];
    [self.testManager2 send:[HLAPIRequest request]
     .setMethod(POST)
     .setBaseURL(@"https://httpbin.org")
     .setCustomURL(@"https://httpbin.org/post")
     .success(^(id result){
        XCTAssertNotNil(result);
        XCTAssertTrue(![NSThread isMainThread]);
        [expectation2 fulfill];
    })
     .failure(^(NSError *error){
        XCTAssertNil(error);
    })];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testSSLPinning {
    XCTestExpectation *expectation = [self expectationWithDescription:@"HLSSLPinningModeCertificate模式请求不成功！"];
    NSString *certPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"httpbin.org" ofType:@"cer"];
    
    [HLNetworkManager setupConfig:^(HLNetworkConfig * _Nonnull config) {
        // Add SSL Pinning Certificate
        HLSecurityPolicyConfig *sConfig = [HLSecurityPolicyConfig policyWithPinningMode:HLSSLPinningModeCertificate];
        sConfig.cerFilePath = certPath;
        config.defaultSecurityPolicy = sConfig;
    }];
    
    [[HLAPIRequest request]
    .setMethod(GET)
    .setCustomURL(@"https://httpbin.org/get")
    .enableDefaultParams(NO)
    .success(^(id result){
        XCTAssertNotNil(result);
        [expectation fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testNetworkReachability {
    NSLog(@"%lu", (unsigned long)[HLNetworkManager reachabilityStatus]);
    XCTAssertTrue([HLNetworkManager reachabilityStatus] == HLReachabilityStatusReachableViaWWAN);
}

@end
