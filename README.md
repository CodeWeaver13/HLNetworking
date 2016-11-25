![HLNetworking: Multi paradigm network request manager based on AFNetworking](https://raw.githubusercontent.com/QianKun-HanLin/HLNetworking/master/loge.png)

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/wangshiyu13/HLQRCodeScanner/blob/master/LICENSE)
[![CI Status](https://img.shields.io/badge/build-1.1.1-brightgreen.svg)](https://travis-ci.org/wangshiyu13/HLQRCodeScanner)
[![CocoaPods](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](http://cocoapods.org/?q= HLQRCodeScanner)
[![Support](https://img.shields.io/badge/support-iOS%208%2B-blue.svg)](https://www.apple.com/nl/ios/)
#### 基于AFNetworking的多范式网络请求管理器
##特点
1. 请求方法链式调用，方便快速
2. 接口请求默认使用统一Session，加快网络访问速度
3. 提供Block和Delegate两种回调方式
4. 请求接口与回调接口分离，方便程序解耦
5. 提供多种参数预设值、拼接表单方便简单
6. 提供断点续传下载API

====

##使用方法

### 一、HLAPI相关

1) config设置

```objective-c
HLNetworkConfig *config = [HLNetworkConfig config];
config.baseURL = @"https://httpbin.org";
config.apiVersion = @"v100";
[[HLAPIManager shared] setConfig:config];
```

2) 链式调用，使用block回调

```objective-c
HLAPI *myAPI = [[HLAPI API].setMethod(GET)
    							.setPath(@"get")
    							.setParams(@{@"user_id": @1})
    							.setDelegate(self)
    							.success(^(id  _Nonnull responseObject) {
        							NSLog(@"\napi 1 --- 已回调 \n----");
    							})
    							.progress(^(NSProgress *proc){
        						NSLog(@"当前进度：%@", proc);
    							})
    							.failure(^(NSError *error){
        							NSLog(@"\napi1 --- 错误：%@", error);
    							})
                				start];
```

3) 请求周期代理 HLRequestDelegate

```objective-c
[HLAPI API].setDelegate(self)

- (void)requestWillBeSent {
    NSLog(@"willBeSent");
}

- (void)requestDidSent {
    NSLog(@"didSent");
}
```

4) 回调结果代理

```objective-c
[[HLAPIManager shared] registerNetworkResponseObserver:self];

// 设置监听的API
- (NSArray<HLAPI *> *)requestAPIs {
    return @[self.api1, self.api2, self.api3, self.api4, self.api5];
}

/**
请求成功的回调

@param responseObject 回调对象
*/
- (void)requestSucessWithResponseObject:(id)responseObject atAPI:(HLAPI *)api {
    NSLog(@"\n%@------RequestSuccessDelegate\n", [self getAPIName:api]);
    NSLog(@"%@", [NSThread currentThread]);
}

/**
请求失败的回调

@param error 错误对象
*/
- (void)requestFailureWithResponseError:(NSError *)error atAPI:(HLAPI *)api {
    NSLog(@"\n%@------RequestFailureDelegate\n", [self getAPIName:api]);
    NSLog(@"%@", [NSThread currentThread]);
}

/**
*  api 上传、下载等长时间执行的Progress进度
*  NSProgress: 进度
*/
- (void)requestProgress:(NSProgress *)progress atAPI:(HLAPI *)api {
    NSLog(@"\n%@------RequestProgress\n", [self getAPIName:api]);
    NSLog(@"%@", [NSThread currentThread]);
}

- (void)dealloc {
    [[HLAPIManager shared] removeNetworkResponseObserver:self];
}
```

5) POST拼接formdata

```objective-c
// 拼接formData
[HLAPI API].formData(^(id<HLMultipartFormDataProtocol> _Nonnull formData) {
    [formData appendPartWithHeaders:@{@"contentType": @"html/text"} body:[NSData data]];
});

// 使用HLFormDataConfig
[HLAPI API].formData(
[HLFormDataConfig configWithData:[NSData data]
                            name:@"name"
                        fileName:@"fileName"
                        mimeType:@"type"]);
```

6) 异步请求Batch

```objective-c
HLAPIBatchRequests *batch = [[HLAPIBatchRequests alloc] init];
// 添加单个api
[batch addAPIRequest:[HLAPI API]];
// 添加apis集合
[batch addBatchAPIRequests:[NSSet setWithObjects:api1, api2, api3, nil]];

[batch start];

batch.delegate = self;

// batch全部完成之后调用 
- (void)batchAPIRequestsDidFinished:(HLAPIBatchRequests * _Nonnull)batchApis {
    NSLog(@"%@", batchApis);
}
```

7) 同步请求Batch

```objective-c
HLAPISyncBatchRequests *syncBatch = [[HLAPISyncBatchRequests alloc] init];
syncBatch.delegate = self;
[syncBatch addBatchAPIRequests:@[self.api1, self.api2, self.api3, self.api4, self.api5]];
[syncBatch start];

// batch全部完成之后调用 
- (void)batchRequestsAllDidFinished:(HLAPISyncBatchRequests *)batchApis {
    NSLog(@"batchRequestsAllDidFinished");
}
```

8) 自定义ObjectReformer

```objective-c
HLAPI * api = [HLAPI API];
api.objReformerDelegate = self;

- (nullable id)apiResponseObjReformerWithAPI:(HLAPI *)api andResponseObject:(id)responseObject andError:(NSError * _Nullable)error {
    // 自定义reformer方法
    MyModel *model [MyReformer reformerWithResponse: id];
    return model;
}
```

### 二、HLTask相关

1) config设置

```objective-c
HLNetworkConfig *config = [HLNetworkConfig config];
config.baseURL = @"https://httpbin.org";
config.isBackgroundSession = YES;
[[HLTaskManager shared] setConfig:config];
[[HLTaskManager shared] registerNetworkResponseObserver:self];
```

2) 链式调用设置Task

```objective-c
HLTask *task = [[HLTask task].setDelegate(self)
    .setFilePath([[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Boom2.dmg"])
    .setTaskURL(@"https://dl.devmate.com/com.globaldelight.Boom2/Boom2.dmg") start];
```

3) 请求周期代理 HLTaskRequestDelegate

```objective-c
[HLTask task].setDelegate(self)

#pragma mark - task request delegate
- (void)requestWillBeSentWithTask:(HLTask *)task {
    
}
// 请求已经发出
- (void)requestDidSentWithTask:(HLTask *)task {
    
}
```

4) 请求回调代理

```
[HLTaskManager shared].responseDelegate = self;

#pragma mark - task reponse protocol
// 设置监听的task
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
```

## 环境要求

该库需运行在 iOS 8.0 和 Xcode 7.0以上环境.

## 集成方法

HLNetworking is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "HLNetworking"
```

## 作者

wangshiyu13, wangshiyu13@163.com

## 开源协议

HLNetworking is available under the MIT license. See the LICENSE file for more info.
