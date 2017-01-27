//
//  ViewController.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2016/9/22.
//  Copyright © 2016年 wangshiyu13. All rights reserved.
//
#import "ViewController.h"
#import "HLNetworking.h"
#import "HLAPICenter+home.h"

static dispatch_queue_t my_api_queue() {
    static dispatch_queue_t my_api_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        my_api_queue = dispatch_queue_create("com.qkhl.queue", DISPATCH_QUEUE_SERIAL);
    });
    return my_api_queue;
}

@interface ViewController ()<HLNetworkResponseDelegate, HLURLRequestDelegate, HLRequestGroupDelegate, HLReformerDelegate, HLNetworkCustomLoggerDelegate>
@property(nonatomic, strong)HLAPIRequest *api1;
@property(nonatomic, strong)HLAPIRequest *api2;
@property(nonatomic, strong)HLAPIRequest *api3;
@property(nonatomic, strong)HLAPIRequest *api4;
@property(nonatomic, strong)HLAPIRequest *api5;
@property(nonatomic, strong)HLAPIRequest *api6;
@property(nonatomic, strong)HLAPIRequest *api7;

@property(nonatomic, strong)HLTaskRequest *task1;

@property(nonatomic, strong) NSMutableArray *taskArray;

@property(nonatomic, assign)BOOL isPause;

@property(nonatomic, strong) id model;
@end

@implementation ViewController

- (HLTaskRequest *)task1 {
    if (!_task1) {
        _task1 = [HLTaskRequest request]
        .setDelegate(self)
        .setFilePath([[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"minion_01.mp4"])
        .setCustomURL(@"http://120.25.226.186:32812/resources/videos/minion_01.mp4")
        .progress(^(NSProgress *proc){
            NSLog(@"\n进度=====\n当前进度：%@", proc);
        })
        .success(^(id response){
            NSLog(@"\n完成=====\n对象：%@", response);
        })
        .failure(^(NSError *error){
            NSLog(@"\n失败=====\n错误：%@", error);
        });
    }
    return _task1;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // setupLogger
    [HLNetworkLogger setupConfig:^(HLNetworkLoggerConfig * _Nonnull config) {
        config.enableLocalLog = YES;
        config.logAutoSaveCount = 5;
        config.loggerType = HLNetworkLoggerTypePlist;
    }];
    [HLNetworkLogger setDelegate:self];
    [HLNetworkLogger startLogging];
    
    // setupNetwork
    [HLNetworkManager setupConfig:^(HLNetworkConfig * _Nonnull config) {
        config.request.baseURL = @"https://httpbin.org";
        config.policy.isBackgroundSession = NO;
        config.request.apiVersion = nil;
//        config.request.retryCount = 4;
    }];
//    [HLNetworkManager registerResponseObserver:self];
    
    
//    [self testTask];
    [self testAPI];
    
//    [self testButton];
//    [self testHome];
}

- (void)testHome {
    [HLAPICenter.home.success(^(id responce) {
        self.model = responce;
    }).failure(^(NSError *obj){
        NSLog(@"----%@", obj);
    }) start];
}

- (void)testButton {
    self.isPause = YES;
    UIButton *pauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    pauseButton.frame = CGRectMake(0, 0, 100, 100);
    pauseButton.backgroundColor = [UIColor redColor];
    [self.view addSubview:pauseButton];
    [pauseButton addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
}

- (void)start {
    if (self.isPause) {
        [self.task1 resume];
    } else {
        [self.task1 cancel];
    }
    self.isPause = !self.isPause;
}

- (void)testTask {
    self.taskArray = [NSMutableArray array];
    for (int i = 1; i<=5; i++) {
        NSString *url = [NSString stringWithFormat:@"http://120.25.226.186:32812/resources/videos/minion_%02d.mp4", i];
        HLTaskRequest *task = [HLTaskRequest request]
        .setDelegate(self)
        .setFilePath([[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"minion_%02d.mp4", i]])
        .setCustomURL(url);
        [self.taskArray addObject:task];
    }
    
    HLRequestGroup *group = [HLRequestGroup groupWithMode:HLRequestGroupModeChian];
    group.delegate = self;
    [group addRequests:self.taskArray];
    [group start];
}

- (void)testAPI {
    __block int i = 0;
    HLRequestGroup *group = [HLRequestGroup groupWithMode:HLRequestGroupModeChian];
    group.delegate = self;
    group.maxRequestCount = 1;
    
    self.api1 = [HLAPIRequest request]
    .setMethod(GET)
    .setPath(@"user-agent")
    .setDelegate(self)
    .setObjReformerDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 1 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
        self.api4.setParams(@{@"show_env": @(i)});
    });
    
    self.api2 = [HLAPIRequest request]
    .setMethod(HEAD)
    .setPath(@"headers")
    .setDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 2 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
    });
    
    self.api3 = [HLAPIRequest request]
    .setMethod(GET)
    .setPath(@"get")
    .setParams(@{@"a": @(i)})
    .setDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 3 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
    });
    
    self.api4 = [HLAPIRequest request]
    .setMethod(POST)
    .setPath(@"post")
    .setDelegate(self)
    .success(^(id  obj) {
        NSLog(@"\napi 4 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
    });
    
    self.api5 = [HLAPIRequest request]
    .setMethod(PATCH)
    .setPath(@"patch")
    .setDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 5 --- 已回调 %@ \n----", obj);
        NSLog(@"%d", i++);
    });
    
    self.api6 = [HLAPIRequest request]
    .setMethod(PUT)
    .setPath(@"put")
    .setDelegate(self)
    .success(^(id obj) {
        NSLog(@"\napi 6 --- 已回调 %@ \n----",obj);
        NSLog(@"%d", i++);
    });
    
    self.api7 = [HLAPIRequest request]
    .setMethod(DELETE)
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
    [group addRequests:@[self.api1, self.api2, self.api3, self.api4, self.api5, self.api6, self.api7]];
    [group start];
    
//    [asyncBatch addAPIs:[NSSet setWithObjects:self.api1, self.api2, self.api3, self.api4, self.api5, self.api6, self.api7, nil]];
//    [asyncBatch start];
}

- (void)requestGroupAllDidFinished:(__kindof HLRequestGroup *)apiGroup {
    NSLog(@"apiGroupAllDidFinished");
//    for (NSString *path in [HLNetworkLogger logFilePaths]) {
//        NSLog(@"%@", path);
//    }
}

#pragma mark - HLObjReformerProtocol
- (id)reformerObject:(id)responseObject andError:(NSError *)error atRequest:(HLAPIRequest *)request {
    return [NSString stringWithFormat:@"我被转换了"];
}

#pragma mark - HLRequestDelegate
- (void)requestWillBeSent:(HLURLRequest *)request {
    NSString *newToken = @"获取了新token";
    ((HLAPIRequest *)request)
    .addParams(@{@"token": newToken})
    .success(^(id obj) {
        NSLog(@"\napi x --- 已回调 %@ \n----", obj);
    });
    NSLog(@"\n%@---willBeSent---", request.hashKey);
}

- (void)requestDidSent:(HLURLRequest *)request {
    NSLog(@"\n%@---didSent---", request.hashKey);
}

#pragma mark - HLResponseDelegate

- (NSArray<HLURLRequest *> *)observerRequests {
    return self.taskArray;
}

// 进度的回调
- (void)requestProgress:(nullable NSProgress *)progress atRequest:(nullable HLURLRequest *)request {
    NSLog(@"\n%@------RequestProgress--------%@\n", request.hashKey, progress);
    NSLog(@"%@", [NSThread currentThread]);
}
// 请求成功的回调
- (void)requestSucess:(nullable id)responseObject atRequest:(nullable HLURLRequest *)request {
    NSLog(@"\n%@------RequestSuccessDelegate\n", request.hashKey);
    NSLog(@"%@", [NSThread currentThread]);
}
// 请求失败的回调
- (void)requestFailure:(nullable NSError *)error atRequest:(nullable HLURLRequest *)request {
    NSLog(@"\n%@------RequestFailureDelegate------%@\n", request.hashKey, error);
    NSLog(@"%@", [NSThread currentThread]);
}

- (NSDictionary *)customInfoWithMessage:(HLDebugMessage *)message {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"Time"] = message.timeString;
    dict[@"RequestObject"] = [message.requestObject toDictionary];
    dict[@"Response"] = [message.response toDictionary];
    return [dict copy];
}

- (NSDictionary *)customHeaderWithMessage:(HLNetworkLoggerConfig *)config {
    return @{@"AppInfo": @{@"OSVersion": [UIDevice currentDevice].systemVersion,
                           @"DeviceType": [UIDevice currentDevice].hl_machineType,
                           @"UDID": [UIDevice currentDevice].hl_udid,
                           @"UUID": [UIDevice currentDevice].hl_uuid,
                           @"MacAddressMD5": [UIDevice currentDevice].hl_macaddressMD5,
                           @"ChannelID": config.channelID,
                           @"AppKey": config.appKey,
                           @"AppName": config.appName,
                           @"AppVersion": config.appVersion,
                           @"ServiceType": config.serviceType}};
}

- (void)dealloc {
    [HLNetworkManager removeResponseObserver:self];
}
@end
