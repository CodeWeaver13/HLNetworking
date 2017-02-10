//
//  HLAPIRequestTest.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/2/9.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLTestCase.h"

@interface HLAPIRequestTest : HLTestCase

@end

@implementation HLAPIRequestTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGET {
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET请求失败"];
    [[HLAPIRequest request]
     .setMethod(GET)
     .setPath(@"get")
     .success(^(id result){
        XCTAssertNotNil(result);
        [expectation fulfill];
    })
     .failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testGETWithParameters {
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET请求失败"];
    [[HLAPIRequest request]
     .setMethod(GET)
     .setCustomURL(@"https://httpbin.org/get")
     .setParams(@{@"key": @"value"})
     .enableDefaultParams(NO)
     .success(^(id result){
        XCTAssertTrue([result[@"args"][@"key"] isEqualToString:@"value"]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPOSTWithForm {
    XCTestExpectation *expectation = [self expectationWithDescription:@"POST请求失败"];
    [[HLAPIRequest request]
     .setMethod(POST)
     .setBaseURL(@"https://httpbin.org/")
     .setPath(@"post")
     .setParams(@{@"key": @"value"})
     .setRequestType(RequestHTTP)
     .setResponseType(ResponseJSON)
     .success(^(id result){
        XCTAssertTrue([result[@"form"][@"key"] isEqualToString:@"value"]);
        XCTAssertTrue([result[@"form"][@"global_param"] isEqualToString:@"global param value"]);
        XCTAssertTrue([result[@"headers"][@"Global-Header"] isEqualToString:@"global header value"]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPOSTWithJSON {
    XCTestExpectation *expectation = [self expectationWithDescription:@"POST请求失败"];
    [[HLAPIRequest request]
     .setMethod(POST)
     .setBaseURL(@"https://httpbin.org/")
     .setPath(@"post")
     .setParams(@{@"key": @"value"})
     .setRequestType(RequestJSON)
     .success(^(id result){
        XCTAssertTrue([result[@"json"][@"key"] isEqualToString:@"value"]);
        XCTAssertTrue([result[@"json"][@"global_param"] isEqualToString:@"global param value"]);
        XCTAssertTrue([result[@"headers"][@"Global-Header"] isEqualToString:@"global header value"]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPOSTWithPlist {
    XCTestExpectation *expectation = [self expectationWithDescription:@"POST请求失败"];
    [[HLAPIRequest request]
     .setMethod(POST)
     .setHeader(nil)
     .enableDefaultParams(NO)
     .setBaseURL(@"https://httpbin.org/")
     .setPath(@"post")
     .setParams(@{@"key1": @"value1", @"key2": @"value2"})
     .setRequestType(RequestPlist)
     .success(^(id result){
        NSString *data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>key1</key>\n\t<string>value1</string>\n\t<key>key2</key>\n\t<string>value2</string>\n</dict>\n</plist>\n";
        XCTAssertTrue([result[@"data"] isEqualToString:data]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPOSTWithFormData {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"POST formdata请求不成功"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"上传进度回调失败"];
    
    // `NSData` form data.
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"testImage" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
//    NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
    // `NSURL` form data.
    //NSString *path = [NSHomeDirectory() stringByAppendingString:@"/Documents/testImage.jpg"];
    //NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
    //NSError *error = nil;
    
    [[HLAPIRequest request]
     .setMethod(POST)
     .setHeader(nil)
     .enableDefaultParams(NO)
     .setBaseURL(@"https://httpbin.org/")
     .setPath(@"post")
     .setRequestType(RequestPlist)
     .formData(/**
                [HLFormDataConfig configWithData:fileData
                name:@"image"
                fileName:@"tempImage.jpg"
                mimeType:@"image/jpeg"]
                
                [HLFormDataConfig configWithFileURL:fileURL
                name:@"image"
                fileName:@"tempImage.jpg"
                mimeType:@"image/jpeg"
                error:&error]
                */
               [HLFormDataConfig configWithImage:image
                                            name:@"image"
                                        fileName:@"tempImage.jpg"
                                         quality:1.0])
     .progress(^(NSProgress *proc){
        if (proc.fractionCompleted == 1.0) {
            [expectation2 fulfill];
        }
    })
     .success(^(id result){
        XCTAssertNotNil(result);
        XCTAssertTrue(result[@"files"][@"image"] != nil);
        [expectation1 fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testResponseWithRAW {
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET请求，HTTP解析失败"];
    [[HLAPIRequest request]
     .setMethod(GET)
     .setPath(@"html")
     .setResponseType(ResponseHTTP)
     .success(^(id result){
        XCTAssertNotNil(result);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testResponseWithJSON {
    XCTestExpectation *expectation = [self expectationWithDescription:@"POST请求，JSON解析失败"];
    [[HLAPIRequest request]
     .setMethod(POST)
     .setPath(@"https://httpbin.org/")
     .setPath(@"post")
     .setHeader(nil)
     .enableDefaultParams(NO)
     .setParams(@{@"key1": @"value1", @"key2": @"value2"})
     .setResponseType(ResponseJSON)
     .success(^(id result){
        XCTAssertTrue([result[@"form"][@"key1"] isEqualToString:@"value1"]);
        XCTAssertTrue([result[@"form"][@"key2"] isEqualToString:@"value2"]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testResponseWithXML {
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET请求，XML解析失败"];

    [[HLAPIRequest request]
     .setMethod(GET)
     .setHeader(nil)
     .setPath(@"xml")
     .enableDefaultParams(NO)
     .setResponseType(ResponseXML)
     .success(^(id result){
        XCTAssertTrue([result isKindOfClass:[NSXMLParser class]]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testHEAD {
    XCTestExpectation *expectation = [self expectationWithDescription:@"HEAD请求失败"];
    [[HLAPIRequest request]
     .setMethod(HEAD)
     .setHeader(nil)
     .setPath(@"get")
     .enableDefaultParams(NO)
     .success(^(id result){
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPUT {
    XCTestExpectation *expectation = [self expectationWithDescription:@"PUT请求失败"];
    [[HLAPIRequest request]
     .setMethod(PUT)
     .setHeader(nil)
     .setPath(@"put")
     .setParams(@{@"key": @"value"})
     .enableDefaultParams(NO)
     .success(^(id result){
        XCTAssertTrue([result[@"form"][@"key"] isEqualToString:@"value"]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testDELETE {
    XCTestExpectation *expectation = [self expectationWithDescription:@"DELETE请求失败"];
    [[HLAPIRequest request]
     .setMethod(DELETE)
     .setHeader(nil)
     .setPath(@"delete")
     .setParams(@{@"key": @"value"})
     .enableDefaultParams(NO)
     .success(^(id result){
        XCTAssertTrue([result[@"args"][@"key"] isEqualToString:@"value"]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPATCH {
    XCTestExpectation *expectation = [self expectationWithDescription:@"PATCH请求失败"];
    [[HLAPIRequest request]
     .setMethod(PATCH)
     .setHeader(nil)
     .setPath(@"patch")
     .setParams(@{@"key": @"value"})
     .enableDefaultParams(NO)
     .success(^(id result){
        XCTAssertTrue([result[@"form"][@"key"] isEqualToString:@"value"]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUserAgnet {
    XCTestExpectation *expectation = [self expectationWithDescription:@"自定义user-agent请求失败"];
    [[HLAPIRequest request]
     .setMethod(GET)
     .setHeader(nil)
     .setPath(@"user-agent")
     .enableDefaultParams(NO)
     .setHeader(@{@"User-Agent": @"XMNetworking Custom User Agent"})
     .success(^(id result){
        XCTAssertTrue([result[@"user-agent"] isEqualToString:@"XMNetworking Custom User Agent"]);
        [expectation fulfill];
    }).failure(^(NSError *error){
        XCTAssertNil(error);
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testRequestWithFailure {
    XCTestExpectation *expectation = [self expectationWithDescription:@"请求没有失败"];
    [[HLAPIRequest request]
     .setMethod(GET)
     .setCustomURL(@"https://httpbin.org/status/404")
     .setHeader(nil)
     .enableDefaultParams(NO)
     .success(^(id result){
        XCTAssertNil(result);
    }).failure(^(NSError *error){
        XCTAssertNotNil(error);
        [expectation fulfill];
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testTimeOut {
    XCTestExpectation *expectation = [self expectationWithDescription:@"请求未超时！"];
    [[HLAPIRequest request]
     .setMethod(GET)
     .setCustomURL(@"https://kangzubin.cn/test/timeout.php")
     .setHeader(nil)
     .setTimeout(5.0)
     .enableDefaultParams(NO)
     .success(^(id result){
        XCTAssertNil(result);
    }).failure(^(NSError *error){
        XCTAssertNotNil(error);
        XCTAssertTrue(error.code == NSURLErrorTimedOut);
        [expectation fulfill];
    }) start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testCancelRunningRequest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"请求没有手动取消！"];
    
     HLAPIRequest *request = [[HLAPIRequest request]
     .setMethod(GET)
     .setCustomURL(@"https://kangzubin.cn/test/timeout.php")
     .setHeader(nil)
     .enableDefaultParams(NO)
     .success(^(id result){
        XCTAssertNil(result);
    }).failure(^(NSError *error){
        XCTAssertNotNil(error);
        XCTAssertTrue(error.code == NSURLErrorCancelled);
        [expectation fulfill];
    }) start];
    
    sleep(2);
    
    [request cancel];
    
    XCTAssertNotNil(request.success);
    XCTAssertNotNil(request.failure);
    
    [self waitForExpectationsWithCommonTimeout];
}
@end
