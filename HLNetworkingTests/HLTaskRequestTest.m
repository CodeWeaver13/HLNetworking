//
//  HLTaskRequestTest.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/2/9.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLTestCase.h"

@interface HLTaskRequestTest : HLTestCase

@end

@implementation HLTaskRequestTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDownload {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"下载请求失败"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"下载进度回调失败"];
    
    [[HLTaskRequest request]
     .setTaskType(Download)
     .setCustomURL(@"https://httpbin.org/image/png")
     .setFilePath([NSHomeDirectory() stringByAppendingString:@"/Documents/temp.png"])
     .progress(^(NSProgress *proc){
        if (proc.fractionCompleted == 1.0) {
            [expectation2 fulfill];
        }
    })
     .success(^(id result){
        XCTAssertNotNil(result);
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:((NSURL *)result).path]);
        [expectation1 fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUpload {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"testImage" ofType:@"jpg"];

    XCTestExpectation *expectation1 = [self expectationWithDescription:@"上传请求失败"];
//    XCTestExpectation *expectation2 = [self expectationWithDescription:@"上传进度回调失败"];
    
    [[HLTaskRequest request]
     .setTaskType(Upload)
     .setCustomURL(@"https://httpbin.org/post")
     .setFilePath(path)
     .progress(^(NSProgress *proc){
        NSLog(@"%@", proc);
        if (proc.fractionCompleted == 1.0) {
//            [expectation2 fulfill];
        }
    })
     .success(^(id result){
        XCTAssertNotNil(result);
        XCTAssertTrue(result[@"data"] != nil);
        [expectation1 fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    
    [self waitForExpectationsWithCommonTimeout];
}
@end
