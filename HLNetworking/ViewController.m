//
//  ViewController.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/22.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//
#import "ViewController.h"
#import "HLNetworking.h"
#import "AFNetworking.h"
#import "HLAPICenter+home.h"
#import "HLNetworkLogger.h"

static dispatch_queue_t my_api_queue() {
    static dispatch_queue_t my_api_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        my_api_queue = dispatch_queue_create("com.qkhl.queue", DISPATCH_QUEUE_SERIAL);
    });
    return my_api_queue;
}

@interface ViewController ()<HLAPIResponseDelegate, HLAPIRequestDelegate, HLObjReformerProtocol, HLAPIChainRequestsProtocol, HLAPIBatchRequestsProtocol, HLTaskRequestDelegate, HLTaskResponseProtocol>
@property(nonatomic, strong)HLAPI *api1;
@property(nonatomic, strong)HLAPI *api2;
@property(nonatomic, strong)HLAPI *api3;
@property(nonatomic, strong)HLAPI *api4;
@property(nonatomic, strong)HLAPI *api5;
@property(nonatomic, strong)HLAPI *api6;
@property(nonatomic, strong)HLAPI *api7;

@property(nonatomic, strong)HLTask *task1;

@property(nonatomic, assign)BOOL isPause;

@property(nonatomic, strong) id model;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupAPINetworkConfig];
    [self testAPI];
//    [self testHome];
}

- (void)testHome {
    [HLAPICenter.home.success(^(id responce) {
        self.model = responce;
    }).failure(^(NSError *obj){
        NSLog(@"----%@", obj);
    }) start];
}

- (void)pause {
    if (self.isPause) {
        [self.task1 resume];
    } else {
        [self.task1 cancel];
    }
    self.isPause = !self.isPause;
}

- (void)testTask {
    self.isPause = NO;
    UIButton *pauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    pauseButton.frame = CGRectMake(0, 0, 100, 100);
    pauseButton.backgroundColor = [UIColor redColor];
    [self.view addSubview:pauseButton];
    [pauseButton addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    self.task1 = [[HLTask task]
                  .setDelegate(self)
                  .setFilePath([[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Boom2.dmg"])
                  .setTaskURL(@"https://dl.devmate.com/com.globaldelight.Boom2/Boom2.dmg") start];
}

- (void)setupTaskNetworkConfig {
    [HLTaskManager setupConfig:^(HLNetworkConfig * _Nonnull config) {
        config.request.baseURL = @"https://httpbin.org";
        config.policy.isBackgroundSession = NO;
    }];
    [HLTaskManager registerResponseObserver:self];
}

#pragma mark - task reponse protocol

- (NSArray<HLTask *> *)requestTasks {
    return @[self.task1];
}

- (void)requestProgress:(nullable NSProgress *)progress atTask:(nullable HLTask *)task {
    NSLog(@"\n进度=====\n当前任务：%@\n当前进度：%@", task.taskURL, progress);
}

- (void)requestSucessWithResponseObject:(nonnull id)responseObject atTask:(nullable HLTask *)task {
    NSLog(@"\n完成=====\n当前任务：%@\n对象：%@", task, responseObject);
}

- (void)requestFailureWithResponseError:(nullable NSError *)error atTask:(nullable HLTask *)task {
    NSLog(@"\n失败=====\n当前任务：%@\n错误：%@", task, error);
}

#pragma mark - task request delegate
- (void)requestWillBeSentWithTask:(HLTask *)task {
    
}
// 请求已经发出
- (void)requestDidSentWithTask:(HLTask *)task {
    
}

- (void)setupAPINetworkConfig {
    [HLAPIManager setupConfig:^(HLNetworkConfig * _Nonnull config) {
        config.request.baseURL = @"https://httpbin.org/";
        config.request.apiVersion = nil;
        config.request.retryCount = 5;
//        config.request.apiCallbackQueue = my_api_queue();
//        config.enableGlobalLog = YES;
    }];
    [HLNetworkLogger setupConfig:^(HLNetworkLoggerConfig * _Nonnull config) {
        config.enableLocalLog = YES;
    }];
    [HLAPIManager registerResponseObserver:self];
}

- (void)testAPI {
    __block int i = 0;
    HLAPIChainRequests *chain = [[HLAPIChainRequests alloc] init];
    chain.delegate = self;
    HLAPIBatchRequests *asyncBatch = [[HLAPIBatchRequests alloc] init];
    asyncBatch.delegate = self;
    
    self.api1 = [HLAPI API].setMethod(GET)
    .setPath(@"user-agent")
    .setDelegate(self)
    .setObjReformerDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 1 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
        self.api4.setParams(@{@"show_env": @(i)});
    });
    
    self.api2 = [HLAPI API].setMethod(HEAD)
    .setPath(@"headers")
    .setDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 2 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
    });
    
    self.api3 = [HLAPI API].setMethod(GET)
    .setPath(@"get")
    .setParams(@{@"a": @(i)})
    .setDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 3 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
    });
    
    self.api4 = [HLAPI API].setMethod(POST)
    .setPath(@"post")
    .setDelegate(self)
    .success(^(id  obj) {
        NSLog(@"\napi 4 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
    });
    
    self.api5 = [HLAPI API].setMethod(PATCH)
    .setPath(@"patch")
    .setDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 5 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
    });
    
    self.api6 = [HLAPI API].setMethod(PUT)
    .setPath(@"put")
    .setDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 6 --- 已回调 %@ \n----",obj);
        NSLog(@"%d", i++);
    });
    
    self.api7 = [HLAPI API].setMethod(DELETE)
    .setPath(@"delete")
    .setDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 7 --- 已回调 %@ \n----",obj);
        NSLog(@"%d", i++);
    });
    
//    [self.api1 start];
//    [self.api2 start];
//    [self.api3 start];
//    [self.api4 start];
//    [self.api5 start];
//    [self.api6 start];
//    [self.api7 start];
    [chain addAPIs:@[self.api1, self.api2, self.api3, self.api4, self.api5, self.api6, self.api7]];
    [chain start];
    
//    [asyncBatch addAPIs:[NSSet setWithObjects:self.api1, self.api2, self.api3, self.api4, self.api5, self.api6, self.api7, nil]];
//    [asyncBatch start];
}

- (void)chainRequestsAllDidFinished:(HLAPIChainRequests *)chainApis {
    NSLog(@"chainRequestsAllDidFinished");
}

- (void)batchAPIRequestsDidFinished:(HLAPIBatchRequests *)batchApis {
    NSLog(@"batchAPIRequestsDidFinished");
}

#pragma mark - HLObjReformerProtocol
- (id)objReformerWithAPI:(HLAPI *)api andResponseObject:(id)responseObject andError:(NSError *)error {
    return [NSString stringWithFormat:@"我被转换了"];
}

#pragma mark - HLRequestDelegate
- (void)requestWillBeSentWithAPI:(HLAPI *)api {
    NSLog(@"\n%@---willBeSent---", [self getAPIName:api]);
}

- (void)requestDidSentWithAPI:(HLAPI *)api {
    NSLog(@"\n%@---didSent---", [self getAPIName:api]);
}

#pragma mark - HLResponseDelegate

HLObserverAPIs(self.api1, self.api2, self.api3, self.api4, self.api5, self.api6, self.api7)

- (void)requestSucessWithResponseObject:(id)responseObject atAPI:(HLAPI *)api {
    NSLog(@"\n%@------RequestSuccessDelegate\n", [self getAPIName:api]);
    NSLog(@"%@", [NSThread currentThread]);
}

- (void)requestFailureWithResponseError:(NSError *)error atAPI:(HLAPI *)api {
    NSLog(@"\n%@------RequestFailureDelegate\n", [self getAPIName:api]);
    NSLog(@"%@", [NSThread currentThread]);
}

- (void)requestProgress:(NSProgress *)progress atAPI:(HLAPI *)api {
    NSLog(@"\n%@------RequestProgress\n", [self getAPIName:api]);
    NSLog(@"%@", [NSThread currentThread]);
}

- (NSString *)getAPIName:(HLAPI *)api {
    NSString *apiName;
    if ([api isEqual:self.api1]) {
        apiName = @"api1";
    } else if ([api isEqual:self.api2]) {
        apiName = @"api2";
    } else if ([api isEqual:self.api3]) {
        apiName = @"api3";
    } else if ([api isEqual:self.api4]) {
        apiName = @"api4";
    } else if ([api isEqual:self.api5]) {
        apiName = @"api5";
    } else if ([api isEqual:self.api6]) {
        apiName = @"api6";
    } else if ([api isEqual:self.api7]) {
        apiName = @"api7";
    }
    return apiName;
}

- (void)dealloc {
    [HLAPIManager removeResponseObserver:self];
    [HLTaskManager removeResponseObserver:self];
}
@end
