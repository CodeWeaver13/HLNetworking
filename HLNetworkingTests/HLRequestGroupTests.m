//
//  HLRequestGroupTests.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/2/9.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLTestCase.h"

@interface HLRequestGroupTests : HLTestCase<HLRequestGroupDelegate>
@property XCTestExpectation *groupExpectation;
@end

@implementation HLRequestGroupTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)requestGroupAllDidFinished:(HLRequestGroup *)apiGroup {
    XCTAssertNotNil(apiGroup);
    [self.groupExpectation fulfill];
}

- (void)testBatchRequest {
    self.groupExpectation = [self expectationWithDescription:@"group请求未完成"];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"api1请求不成功"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"api2请求不成功"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"api3请求不成功"];
    HLRequestGroup *group = [HLRequestGroup groupWithMode:HLRequestGroupModeBatch];
    group.delegate = self;
    
    HLAPIRequest *reqeust1 = [HLAPIRequest request]
    .setMethod(GET)
    .setCustomURL(@"https://httpbin.org/get")
    .setParams(@{@"method": @"get"})
    .success(^(id result){
        XCTAssertTrue([result[@"args"][@"method"] isEqualToString:@"get"]);
        [expectation1 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    HLAPIRequest *reqeust2 = [HLAPIRequest request]
    .setMethod(POST)
    .setCustomURL(@"https://httpbin.org/post")
    .setParams(@{@"method": @"post"})
    .success(^(id result){
        XCTAssertTrue([result[@"form"][@"method"] isEqualToString:@"post"]);
        [expectation2 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    HLAPIRequest *reqeust3 = [HLAPIRequest request]
    .setMethod(PUT)
    .setCustomURL(@"https://httpbin.org/put")
    .setParams(@{@"method": @"put"})
    .success(^(id result){
        XCTAssertTrue([result[@"form"][@"method"] isEqualToString:@"put"]);
        [expectation3 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    [group addRequests:@[reqeust1, reqeust2, reqeust3]];
    [group start];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testBatchRequestWithFailure {
    self.groupExpectation = [self expectationWithDescription:@"group请求未完成"];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"api1请求不成功"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"api2请求成功"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"api3请求不成功"];
    HLRequestGroup *group = [HLRequestGroup groupWithMode:HLRequestGroupModeBatch];
    group.delegate = self;
    
    HLAPIRequest *reqeust1 = [HLAPIRequest request]
    .setMethod(GET)
    .setCustomURL(@"https://httpbin.org/get")
    .setParams(@{@"method": @"get"})
    .success(^(id result){
        XCTAssertTrue([result[@"args"][@"method"] isEqualToString:@"get"]);
        [expectation1 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    HLAPIRequest *reqeust2 = [HLAPIRequest request]
    .setMethod(GET)
    .setCustomURL(@"https://kangzubin.cn/test/timeout.php")
    .setTimeout(5.0)
    .success(^(id result){
        XCTAssertNil(result);
    })
    .failure(^(NSError *error){
        XCTAssertTrue(error.code == NSURLErrorTimedOut);
        [expectation2 fulfill];
    });
    
    HLAPIRequest *reqeust3 = [HLAPIRequest request]
    .setMethod(PUT)
    .setCustomURL(@"https://httpbin.org/put")
    .setParams(@{@"method": @"put"})
    .success(^(id result){
        XCTAssertTrue([result[@"form"][@"method"] isEqualToString:@"put"]);
        [expectation3 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    [group addRequests:@[reqeust1, reqeust2, reqeust3]];
    [group start];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testCancelBatchRequest {
    self.groupExpectation = [self expectationWithDescription:@"group请求未完成"];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"api1请求不成功"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"api2请求成功"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"api3请求不成功"];
    HLRequestGroup *group = [HLRequestGroup groupWithMode:HLRequestGroupModeBatch];
    group.delegate = self;
    
    HLAPIRequest *reqeust1 = [HLAPIRequest request]
    .setMethod(GET)
    .setCustomURL(@"https://httpbin.org/get")
    .setParams(@{@"method": @"get"})
    .success(^(id result){
        XCTAssertTrue([result[@"args"][@"method"] isEqualToString:@"get"]);
        [expectation1 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    HLAPIRequest *reqeust2 = [HLAPIRequest request]
    .setMethod(GET)
    .setCustomURL(@"https://kangzubin.cn/test/timeout.php")
    .setTimeout(5.0)
    .success(^(id result){
        XCTAssertNil(result);
    })
    .failure(^(NSError *error){
        XCTAssertTrue(error.code == NSURLErrorCancelled);
        [expectation2 fulfill];
    });
    
    HLAPIRequest *reqeust3 = [HLAPIRequest request]
    .setMethod(PUT)
    .setCustomURL(@"https://httpbin.org/put")
    .setParams(@{@"method": @"put"})
    .success(^(id result){
        XCTAssertTrue([result[@"form"][@"method"] isEqualToString:@"put"]);
        [expectation3 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    [group addRequests:@[reqeust1, reqeust2, reqeust3]];
    [group start];
    
    sleep(2);
    
    [reqeust2 cancel];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testChainRequest {
    self.groupExpectation = [self expectationWithDescription:@"group请求未完成"];
    
    __block int i = 0;
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"api1请求不成功"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"api2请求不成功"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"api3请求不成功"];
    HLRequestGroup *group = [HLRequestGroup groupWithMode:HLRequestGroupModeChain];
    group.delegate = self;
    
    HLAPIRequest *reqeust1 = [HLAPIRequest request]
    .setMethod(GET)
    .setCustomURL(@"https://httpbin.org/get")
    .setParams(@{@"method": @"get"})
    .success(^(id result){
        XCTAssertTrue([result[@"args"][@"method"] isEqualToString:@"get"]);
        XCTAssertEqual(i, 0);
        i++;
        [expectation1 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    HLAPIRequest *reqeust2 = [HLAPIRequest request]
    .setMethod(POST)
    .setCustomURL(@"https://httpbin.org/post")
    .setParams(@{@"method": @"post"})
    .success(^(id result){
        XCTAssertTrue([result[@"form"][@"method"] isEqualToString:@"post"]);
        XCTAssertEqual(i, 1);
        i++;
        [expectation2 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    HLAPIRequest *reqeust3 = [HLAPIRequest request]
    .setMethod(PUT)
    .setCustomURL(@"https://httpbin.org/put")
    .setParams(@{@"method": @"put"})
    .success(^(id result){
        XCTAssertTrue([result[@"form"][@"method"] isEqualToString:@"put"]);
        XCTAssertEqual(i, 2);
        i++;
        [expectation3 fulfill];
    })
    .failure(^(NSError *error){
        XCTAssertNil(error);
    });
    
    [group addRequests:@[reqeust1, reqeust2, reqeust3]];
    [group start];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testChainRequestWithFailure1 {
//    XCTestExpectation *expectation = [self expectationWithDescription:@"The chain requests should fail."];
//    
//    [XMCenter sendChainRequest:^(XMChainRequest * _Nonnull chainRequest) {
//        
//        [[[chainRequest onFirst:^(XMRequest * _Nonnull request) {
//            request.url = @"https://httpbin.org/get";
//            request.httpMethod = kXMHTTPMethodGET;
//            request.parameters = @{@"method": @"get"};
//        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull sendNext) {
//            if ([responseObject[@"args"][@"method"] isEqualToString:@"get"]) {
//                request.url = @"https://httpbin.org/post";
//                request.httpMethod = kXMHTTPMethodPOST;
//                request.parameters = @{@"method": @"post"};
//            } else {
//                *sendNext = NO;
//            }
//        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull sendNext) {
//            // your business validate logic code here.
//            *sendNext = NO;
//        }];
//        
//    } onSuccess:^(NSArray<id> * _Nonnull responseObjects) {
//        XCTAssertNil(responseObjects);
//    } onFailure:^(NSArray<id> * _Nonnull errors) {
//        XCTAssertTrue(errors.count == 3);
//        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);  // The success response for first request will return in errors array.
//        XCTAssertTrue([errors[1][@"form"][@"method"] isEqualToString:@"post"]); // The success response for second request will return in errors array.
//        XCTAssertTrue([errors[2] isKindOfClass:[NSNull class]]);                // The third request will not sent, and return an [NSNull null] object.
//    } onFinished:^(NSArray<id> * _Nullable responseObjects, NSArray<id> * _Nullable errors) {
//        XCTAssertNil(responseObjects);
//        XCTAssertTrue(errors.count == 3);
//        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);
//        XCTAssertTrue([errors[1][@"form"][@"method"] isEqualToString:@"post"]);
//        XCTAssertTrue([errors[2] isKindOfClass:[NSNull class]]);
//        [expectation fulfill];
//    }];
//    
//    [self waitForExpectationsWithCommonTimeout];
}

- (void)testChainRequestWithFailure2 {
//    XCTestExpectation *expectation = [self expectationWithDescription:@"The chain requests should fail."];
//    
//    [XMCenter sendChainRequest:^(XMChainRequest * _Nonnull chainRequest) {
//        
//        [[chainRequest onFirst:^(XMRequest * _Nonnull request) {
//            request.url = @"https://httpbin.org/get";
//            request.httpMethod = kXMHTTPMethodGET;
//            request.parameters = @{@"method": @"get"};
//        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull sendNext) {
//            if ([responseObject[@"args"][@"method"] isEqualToString:@"get"]) {
//                request.url = @"https://kangzubin.cn/test/timeout.php"; // This interface will return in 30 seconds later.
//                request.httpMethod = kXMHTTPMethodGET;
//                request.timeoutInterval = 5.0;
//            } else {
//                *sendNext = NO;
//            }
//        }];
//        
//    } onSuccess:^(NSArray<id> * _Nonnull responseObjects) {
//        XCTAssertNil(responseObjects);
//    } onFailure:^(NSArray<id> * _Nonnull errors) {
//        XCTAssertTrue(errors.count == 2);
//        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);  // The success response for first request will return in errors array.
//        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorTimedOut);       // The Error info for second request.
//    } onFinished:^(NSArray<id> * _Nullable responseObjects, NSArray<id> * _Nullable errors) {
//        XCTAssertNil(responseObjects);
//        XCTAssertTrue(errors.count == 2);
//        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);
//        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorTimedOut);
//        [expectation fulfill];
//    }];
//    
//    [self waitForExpectationsWithCommonTimeout];
}

- (void)testCancelChainRequest {
//    XCTestExpectation *expectation1 = [self expectationWithDescription:@"The chain requests should succeed."];
//    XCTestExpectation *expectation2 = [self expectationWithDescription:@"The Cancel block should be called."];
//    
//    NSString *identifier = [XMCenter sendChainRequest:^(XMChainRequest * _Nonnull chainRequest) {
//        
//        [[chainRequest onFirst:^(XMRequest * _Nonnull request) {
//            request.url = @"https://httpbin.org/get";
//            request.httpMethod = kXMHTTPMethodGET;
//            request.parameters = @{@"method": @"get"};
//        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull sendNext) {
//            if ([responseObject[@"args"][@"method"] isEqualToString:@"get"]) {
//                request.url = @"https://kangzubin.cn/test/timeout.php"; // This interface will return in 30 seconds later.
//                request.httpMethod = kXMHTTPMethodGET;
//            } else {
//                *sendNext = NO;
//            }
//        }];
//        
//    } onSuccess:^(NSArray<id> * _Nonnull responseObjects) {
//        XCTAssertNil(responseObjects);
//    } onFailure:^(NSArray<id> * _Nonnull errors) {
//        XCTAssertTrue(errors.count == 2);
//        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);  // The success response for first request will return in errors array.
//        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorCancelled);      // The Error info for second request.
//    } onFinished:^(NSArray<id> * _Nullable responseObjects, NSArray<id> * _Nullable errors) {
//        XCTAssertNil(responseObjects);
//        XCTAssertTrue(errors.count == 2);
//        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);
//        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorCancelled);
//        [expectation1 fulfill];
//    }];
//    
//    sleep(2);
//    
//    [XMCenter cancelRequest:identifier onCancel:^(id _Nullable request) {
//        XMChainRequest *chainRequest = request;
//        XCTAssertNotNil(chainRequest);
//        [expectation2 fulfill];
//    }];
//    
//    [self waitForExpectationsWithCommonTimeout];
//    
}

@end
