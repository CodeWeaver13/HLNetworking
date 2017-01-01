![HLNetworking: Multi paradigm network request manager based on AFNetworking](https://raw.githubusercontent.com/QianKun-HanLin/HLNetworking/master/loge.png)
#### 基于AFNetworking的多范式网络请求管理器
[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/wangshiyu13/HLQRCodeScanner/blob/master/LICENSE)
[![CI Status](https://img.shields.io/badge/build-1.2.1-brightgreen.svg)](https://travis-ci.org/wangshiyu13/HLQRCodeScanner)
[![CocoaPods](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](http://cocoapods.org/?q= HLQRCodeScanner)
[![Support](https://img.shields.io/badge/support-iOS%208%2B-blue.svg)](https://www.apple.com/nl/ios/)

## 简介
![](http://p1.bpimg.com/4851/448c29b352237037.png)

HLNetworking整体结构如图所示，是一套基于[AFNetworking 3.1.0](https://github.com/AFNetworking/AFNetworking)封装的网络库，提供了更高层次的抽象和更方便的调用方式。

## 特性
 - 离散式的请求设计，方便进行组件化
 - 支持全局配置请求的公共信息
 - 提供大多数网络访问方式和相应的序列化类型
 - 提供api请求结果映射接口，可以自行转换为相应的数据格式
 - api请求支持多种回调方式（block，delegate）
 - api配置简单，通过block链式调用组装api，配合APICenter中的宏可以极大减少离散式api的设置代码
 - 支持批量请求、链式请求等特殊需求
 - 可随时取消未完成的网络请求，支持断点续传
 - 提供常用的formData拼接方式，可自行扩展
 - 提供请求前网络状态检测，重复请求检测，避免不必要的请求
 - 提供debug回调用于调试

##使用方法

### 头文件的导入

* 如果是通过 CocoaPods 安装，则:

```objc
#import <HLNetworking/HLNetworking.h>
```

* 如果是手动下载源码安装，则:

```objc
#import "HLNetworking.h"
```

### 全局网络配置

```objc
[HLAPIManager setupConfig:^(HLNetworkConfig * _Nonnull config) {
	config.baseURL = @"https://httpbin.org/";
	config.apiVersion = nil;
}];
```

通过调用`HLAPIManager`的`+setupConfig:`方法，修改block中传入的`HLNetworkConfig`对象来配置全局网络请求信息，其中可修改的参数如下：

- **apiCallbackQueue**：自定义的请求队列，如果不设置则自动使用HLAPIManager默认的队列
- **defaultParams**：默认的parameters，可以在HLAPI中选择是否使用，默认开启，该参数不会被覆盖，HLAPI中使用`setParams()`后，请求的params中依然会有该参数
- **defaultHeaders**：默认的header，可以在HLAPI中覆盖
- **AppGroup**：后台模式所用的GroupID，该选项只对Task有影响
- **isBackgroundSession**：是否为后台模式，该选项只对Task有影响
- **generalErrorTypeStr**：出现网络请求时使用的错误提示文字，该文字在failure block中的NSError对象返回；默认为：`服务器连接错误，请稍候重试`
- **frequentRequestErrorStr**：用户频繁发送同一个请求，使用的错误提示文字；默认为：`请求发送速度太快, 请稍候重试`
- **networkNotReachableErrorStr**：网络请求开始时，会先检测相应网络域名的Reachability，如果不可达，则直接返回该错误提示；默认为：`网络不可用，请稍后重试`
- **isErrorCodeDisplayEnabled**：出现网络请求错误时，是否在请求错误的文字后加上`{code}`，默认为YES
- **baseURL**：全局的baseURL，HLAPI的baseURL会覆盖该参数
- **apiVersion**：api版本，用于拼接在请求的Path上，默认为infoPlist中的`CFBundleShortVersionString`，格式为`v{version}{r}`，审核版本为r，例：http://www.baidu.com/v5/s?ie=UTF-8&wd=abc
- **isJudgeVersion**：是否为审核版本，作用于apiVersion，存储在NSUserDefaults中，key为isR
- **userAgent**：UserAgent，request header中的UA，默认为nil
- **maxHttpConnectionPerHost**：每个Host的最大连接数，默认为5
- **requestTimeoutInterval**：请求超时时间，默认为15秒
- **cachePolicy**：请求缓存策略，默认为NSURLRequestUseProtocolCachePolicy
- **URLCache**：URLCache设置
- **isNetworkingActivityIndicatorEnabled**：请求时是否显示网络指示器（状态栏），默认为YES
- **enableReachability**：是否启用reachability，baseURL为domain
- **defaultSecurityPolicy**：默认的安全策略配置，该配置在debug模式下默认为`HLSSLPinningModeNone`，release模式下默认为`HLSSLPinningModePublicKey`，其中详细参数如下：
	- **SSLPinningMode**：SSL Pinning证书的校验模式，默认为 `HLSSLPinningModeNone`
	- **allowInvalidCertificates**：是否允许使用Invalid 证书，默认为 NO
	- **validatesDomainName**：是否校验在证书 CN 字段中的 domain name，默认为 YES
	- **cerFilePath**：cer证书文件路径

### API相关

#### 组装api

```objc
// 组装请求
HLAPI *get = [HLAPI API].setMethod(GET)
    							.setPath(@"get")
    							.setParams(@{@"user_id": @1})
    							.setDelegate(self);

// 手动拼接formData上传
HLAPI *formData = [HLAPI API].formData(^(id<HLMultipartFormDataProtocol> formData) {
    [formData appendPartWithHeaders:@{@"contentType": @"html/text"} body:[NSData data]];
});

// 使用HLFormDataConfig对象拼接上传
[HLAPI API].formData([HLFormDataConfig configWithData:imageData
                                                 name:@"avatar"
                                             fileName:@"fileName"
                                             mimeType:@"type"]);
```

#### block方式接收请求

```objc
// block接收请求
[get.success(^(id result) {
    NSLog(@"\napi 1 --- 已回调 \n----");
})
 .progress(^(NSProgress *proc){
    NSLog(@"当前进度：%@", proc);
})
 .failure(^(NSError *error){
    NSLog(@"\napi1 --- 错误：%@", error);
})
 .debug(^(HLDebugMessage *message){
    NSLog(@"\n debug参数：\n \
          sessionTask = %@\n \
          api = %@\n \
          error = %@\n \
          originRequest = %@\n \
          currentRequest = %@\n \
          response = %@\n",
          message.sessionTask,
          message.api,
          message.error,
          message.originRequest,
          message.currentRequest,
          message.response);
}) start];
```

#### delegate方式接收请求

```objc
// 当前类遵守HLAPIResponseDelegate协议
// 在初始化方法中设置当前类为回调监听
[HLAPIManager registerResponseObserver:self];

// 在这个宏中写入需要监听的api
HLObserverAPIs(self.api1, self.api2)
// 或者用-requestAPIs这个代理方法，这两个完全等效
- (NSArray<HLAPI *> *)requestAPIs {
    return @[self.api1, self.api2, self.api3, self.api4];
}

// 在下面三个代理方法中获取回调结果
// 这是成功的回调
- (void)requestSucessWithResponseObject:(id)responseObject atAPI:(HLAPI *)api {
    NSLog(@"\n%@------RequestSuccessDelegate\n", api);
    NSLog(@"%@", [NSThread currentThread]);
}
// 这是失败的回调
- (void)requestFailureWithResponseError:(NSError *)error atAPI:(HLAPI *)api {
    NSLog(@"\n%@------RequestFailureDelegate\n", api);
    NSLog(@"%@", [NSThread currentThread]);
}
// 这是进度的回调
- (void)requestProgress:(NSProgress *)progress atAPI:(HLAPI *)api {
    NSLog(@"\n%@------RequestProgress\n", api);
    NSLog(@"%@", [NSThread currentThread]);
}

// 切记在dealloc中释放当前控制器
- (void)dealloc {
    [HLAPIManager removeResponseObserver:self];
}
```

**注意1：**设置请求URL时，`setCustomURL`的优先级最高，其次是API中的`setBaseURL`，最后才是全局config中的`baseURL`，另无论是哪种`baseURL`都需要配合`setPath`使用。

**注意2：**一个请求对象的回调 block (success/failure/progress/debug) 是非必需的（默认为 `nil`）。另外，需要注意的是，success/failure/debug等回调 Block 会在 config 设置的 `apiCallbackQueue ` 队列中被执行，但 progress 回调 Block 将在 NSURLSession 自己的队列中执行，而不是 `apiCallbackQueue `，但是所有的回调结果都会回落到主线程。

**注意3：**请求的delegate回调之所以这样设置，是为了可以跨类获取请求回调，因此使用起来稍微麻烦一些，如果只需要在当前类拿到回调，使用block方式即可。

**注意4：**HLAPI 同样支持其他 HTTP 方法，比如：`HEAD`, `DELETE`, `PUT`, `PATCH` 等，使用方式与上述类似，不再赘述。

详见 `HLNetworkConfig`、`HLSecurityPolicyConfig`、`HLAPI`、`HLAPIType` 、`HLAPIManager` 、`HLFormDataConfig`、`HLDebugMessage` 等几个文件中的代码和注释，可选参数基本可以覆盖大多数需求。

#### 请求的生命周期方法
```objc
// 在api组装时设置当前类为代理
[HLAPI API].setDelegate(self)

// 请求即将发出的代理方法
- (void)requestWillBeSent {
    NSLog(@"willBeSent");
}

// 请求已经发出的代理方法
- (void)requestDidSent {
    NSLog(@"didSent");
}
```

#### 自定义请求结果处理逻辑
```objc
// 指定的类需要遵守HLObjReformerProtocol协议
[HLAPI API].setObjReformerDelegate(self);

/**
 一般用来进行JSON -> Model 数据的转换工作。返回的id，如果没有error，则为转换成功后的Model数据。如果有error， 则直接返回传参中的responseObject

 @param api 调用的api
 @param responseObject 请求的返回
 @param error 请求的错误
 @return 整理过后的请求数据
 */
- (nullable id)objReformerWithAPI:(HLAPI *)api 
                andResponseObject:(id)responseObject
                         andError:(NSError * _Nullable)error
{
	if (responseObject) {
		// 在这里处理获得的数据
		// 自定义reformer方法
    	MyModel *model = [MyReformer reformerWithResponse:responseObject];
    	return model;
	} else {
		// 在这里处理异常
		return nil;
	}
}

```

#### 取消一个网络请求

```objc
// 通过api取消网络请求
[self.api1 cancel];

// 通过HLAPIManager取消网络请求
[HLAPIManager cancel: self.api1];

```

**注意：**如果请求已经发出，将无法取消，取消可以注销对应的回调block，但是delegate不会被注销。

### 批量请求

#### 无序请求
HLNetworking 支持同时发一组批量请求，这组请求在业务逻辑上相关，但请求本身是互相独立的，请求时并行执行，`- batchAPIRequestsDidFinished` 会在所有请求都结束时才执行，每个请求的结果由API自身管理。注：回调中的 `HLAPIBatchRequests `里的`apiSet`是无序的。

```obc
HLAPIBatchRequests *batch = [[HLAPIBatchRequests alloc] init];
// 添加单个api
[batch add:[HLAPI API]];
// 添加apis集合
[batch addAPIs:[NSSet setWithObjects:api1, api2, api3, nil]];

[batch start];

batch.delegate = self;

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5), dispatch_get_main_queue(), ^{
	// 使用cancel取消
	[batch cancel];
});

// batch全部完成之后调用 
- (void)batchAPIRequestsDidFinished:(HLAPIBatchRequests * _Nonnull)batchApis {
    NSLog(@"%@", batchApis);
}
```

#### 链式请求
HLNetworking 同样支持发一组链式请求，这组请求之间互相依赖，下一请求是否发送以及请求的参数可以取决于上一个请求的结果，请求时串行执行，`- chainRequestsAllDidFinished` 会在所有请求都结束时才执行，每个请求的结果由API自身管理。注：`HLAPIChainRequests`类做了特殊处理，自身即为`HLAPI`的容器，因此直接`chain[index]`即可获取相应的`HLAPI`对象，也可以直接遍历；回调中的 `chainApis `中元素的顺序与每个链式请求 `HLAPI` 对象的先后顺序一致。

```objc
HLAPIChainRequests *chain = [[HLAPIChainRequests alloc] init];

chain.delegate = self;

[chain addAPIs:@[self.api1, self.api2, self.api3, self.api4, self.api5]];

[chain start];

for (id obj in chain) {
	NSLog(@"%@", obj);
}

HLAPI *api = chain[0];

// chain[0] == self.api1
NSLog(@"%@", api);

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5), dispatch_get_main_queue(), ^{
	// 使用cancel取消
	[chain cancel];
});

// batch全部完成之后调用 
- (void)chainRequestsAllDidFinished:(HLAPIChainRequests *)chainApis {
    NSLog(@"chainRequestsAllDidFinished");
}
```

### 网络可连接性检查

```objc
HLAPIManager提供了八个方法和四个属性用于获取网络的状态，分别如下：

// reachability的状态
typedef NS_ENUM(NSUInteger, HLReachabilityStatus) {
    HLReachabilityStatusUnknown,
    HLReachabilityStatusNotReachable,
    HLReachabilityStatusReachableViaWWAN,
    HLReachabilityStatusReachableViaWiFi
};

// 通过sharedMager单例，获取当前reachability状态
+ (HLReachabilityStatus)reachabilityStatus;
// 通过sharedMager单例，获取当前是否可访问网络
+ (BOOL)isReachable;
// 通过sharedMager单例，获取当前是否使用数据流量访问网络
+ (BOOL)isReachableViaWWAN;
// 通过sharedMager单例，获取当前是否使用WiFi访问网络
+ (BOOL)isReachableViaWiFi;

// 通过sharedMager单例，开启默认reachability监视器，block返回状态
+ (void)listening:(void(^)(HLReachabilityStatus status))listener;

// 通过sharedMager单例，停止reachability监视器监听domain
+ (void)stopListening;

// 监听给定的域名是否可以访问，block内返回状态
- (void)listeningWithDomain:(NSString *)domain listeningBlock:(void (^)(HLReachabilityStatus))listener;

// 停止给定域名的网络状态监听
- (void)stopListeningWithDomain:(NSString *)domain;	
```
**注意：**reachability的监听domain默认为[HLNetworking sharedManager].config.baseURL，当然你也可以通过对象方法自定义domain。

### HTTPS 请求的本地证书校验（SSL Pinning）

在你的应用程序包里添加 (pinned) 相应的 SSL 证书做校验有助于防止中间人攻击和其他安全漏洞。`HLNetworking`的`config`属性和`HLAPI`里有对AFNetworking 的 `AFSecurityPolicy` 安全模块的封装，你可以通过配置`config`内`defaultSecurityPolicy`属性，用于校验本地保存的证书或公钥可信任。

```objc
// SSL Pinning
typedef NS_ENUM(NSUInteger, HLSSLPinningMode) {
    // 不校验Pinning证书
    HLSSLPinningModeNone,
    // 校验Pinning证书中的PublicKey
    HLSSLPinningModePublicKey,
    // 校验整个Pinning证书
    HLSSLPinningModeCertificate
};

// 生成策略
HLSecurityPolicyConfig *securityPolicy = [HLSecurityPolicyConfig policyWithPinningMode:HLSSLPinningModePublicKey];
    // 是否允许使用Invalid 证书，默认为 NO
    securityPolicy.allowInvalidCertificates = NO;
    // 是否校验在证书 CN 字段中的 domain name，默认为 YES
    securityPolicy.validatesDomainName = YES;
    //cer证书文件路径
    securityPolicy.cerFilePath = [[NSBundle mainBundle] pathForResource:@"myCer" ofType:@"cer"];

// 设置默认的安全策略
[HLAPIManager setupConfig:^(HLNetworkConfig * _Nonnull config) {
    config.defaultSecurityPolicy = securityPolicy;
}];

// 针对特定API的安全策略
self.api1.setSecurityPolicy(securityPolicy);
```
**注意：**API中的安全策略会在此api请求时覆盖默认安全策略，并且与api相同baseURL的安全策略都会被覆盖。

### Task相关

HLTask目前支持上传下载功能，已支持断点续传，其中上传是指流上传，即使用UPLOAD方法；如果需要使用POST中的formData拼接方式上传，请参考API相关的formData设置

#### config设置

```objc
[HLTaskManager setupConfig:^(HLNetworkConfig * _Nonnull config) {
	config.baseURL = @"https://httpbin.org";
	config.isBackgroundSession = NO;
}];
[HLTaskManager registerResponseObserver:self];
```

#### 链式调用组装Task

```objc
HLTask *task = [[HLTask task].setDelegate(self)
	 // 设置Task类型，Upload/Download
	 .setTaskType(Upload)
	 // 设置下载或者上传的本地文件路径
    .setFilePath([[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Boom2.dmg"])
    // 设置下载或者上传的地址
    .setTaskURL(@"https://dl.devmate.com/com.globaldelight.Boom2/Boom2.dmg") start];
```

#### Task的生命周期方法

```objc
[HLTask task].setDelegate(self)

#pragma mark - task request delegate
// 请求即将发出
- (void)requestWillBeSentWithTask:(HLTask *)task {
    
}
// 请求已经发出
- (void)requestDidSentWithTask:(HLTask *)task {
    
}
```

#### 请求回调代理

```
[HLTaskManager shared].responseDelegate = self;

#pragma mark - task reponse protocol
// 设置监听的task
HLObserverTasks(self.task1)
// 等同于HLObserverTasks(...)
- (NSArray <HLTask *>*)requestTasks {
    return @[self.task1];
}

// 下载/上传进度回调
- (void)requestProgress:(nullable NSProgress *)progress atTask:(nullable HLTask *)task {
    NSLog(@"\n进度=====\n当前任务：%@\n当前进度：%@", task.taskURL, progress);
}

// 任务完成回调
- (void)requestSucessWithResponseObject:(nonnull id)responseObject atTask:(nullable HLTask *)task {
    NSLog(@"\n完成=====\n当前任务：%@\n对象：%@", task, responseObject);
}

// 任务失败回调
- (void)requestFailureWithResponseError:(nullable NSError *)error atTask:(nullable HLTask *)task {
    NSLog(@"\n失败=====\n当前任务：%@\n错误：%@", task, error);
}
```

**注意1：**Task暂时不支持批量上传/下载。

**注意2：**Task的resume信息记录在沙盒中`Cache/com.qkhl.HLNetworking/downloadDict中`。

### Center相关

``HLAPICenter``提供一种离散式API的组织模版，通过``HLAPIMacro``中定义的宏，可以快速设置模块所需的API

#### 范例


## 环境要求

该库需运行在 iOS 8.0 和 Xcode 7.0以上环境.

## 集成方法

HLNetworking 可以在[CocoaPods](http://cocoapods.org)中获取，将以下内容添加进你的Podfile中后，运行`pod install`即可安装:

```ruby
pod "HLNetworking"
```

如果你只需要用到API相关，可以这样：
```ruby
pod "HLNetworking/API"
```

目前有四个模块可供选择：

     - HLNetworking/Core (1.2.0)
     - HLNetworking/API (1.2.0)
     - HLNetworking/Task (1.2.0)
     - HLNetworking/Center (1.2.0) 

其中Core包含API和Task的所有代码，API和Task相互独立，Center则依赖于API


## 作者

wangshiyu13, wangshiyu13@163.com

## 开源协议

HLNetworking is available under the MIT license. See the LICENSE file for more info.
