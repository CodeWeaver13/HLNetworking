![HLNetworking: Multi paradigm network request manager based on AFNetworking](https://raw.githubusercontent.com/QianKun-HanLin/HLNetworking/master/loge.png)
#### 基于AFNetworking的高阶网络请求管理器
[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/wangshiyu13/HLQRCodeScanner/blob/master/LICENSE)
[![CI Status](https://img.shields.io/badge/build-1.3.0-brightgreen.svg)](https://travis-ci.org/wangshiyu13/HLQRCodeScanner)
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
	config.request.baseURL = @"https://httpbin.org/";
	config.request.apiVersion = nil;
}];
```

通过调用`HLAPIManager`的`+setupConfig:`方法，修改block中传入的`HLNetworkConfig`对象来配置全局网络请求信息，其中可修改的参数如下：

- **tips**：提示相关参数
	- **generalErrorTypeStr**：出现网络请求时使用的错误提示文字，该文字在failure block中的NSError对象返回；默认为：`服务器连接错误，请稍候重试`
	- **frequentRequestErrorStr**：用户频繁发送同一个请求，使用的错误提示文字；默认为：`请求发送速度太快, 请稍候重试`
	- **networkNotReachableErrorStr**：网络请求开始时，会先检测相应网络域名的Reachability，如果不可达，则直接返回该错误提示；默认为：`网络不可用，请稍后重试`
	- **isNetworkingActivityIndicatorEnabled**：请求时是否显示网络指示器（状态栏），默认为 `YES`
- **request**：请求相关参数
	- **apiCallbackQueue**：自定义的请求队列，如果不设置则自动使用HLAPIManager默认的队列，该参数默认为 `nil`
	- **defaultParams**：默认的parameters，可以在HLAPI中选择是否使用，默认开启，该参数不会被覆盖，HLAPI中使用`setParams()`后，请求的params中依然会有该参数，默认为 `nil`
	- **defaultHeaders**：默认的header，可以在HLAPI中覆盖，默认为 `nil`
	- **baseURL**：全局的baseURL，HLAPI的baseURL会覆盖该参数，默认为 `nil`
	- **apiVersion**：api版本，用于拼接在请求的Path上，默认为infoPlist中的`CFBundleShortVersionString`，格式为`v{version}{r}`，审核版本为r，例：http://www.baidu.com/v5/s?ie=UTF-8&wd=abc，默认为 `nil`
	- **isJudgeVersion**：是否为审核版本，作用于apiVersion，存储在NSUserDefaults中，key为isR，默认为 `NO`
	- **userAgent**：UserAgent，request header中的UA，默认为 `nil`
	- **maxHttpConnectionPerHost**：每个Host的最大连接数，默认为 `5`
	- **requestTimeoutInterval**：请求超时时间，默认为 `15` 秒
- **policy**：网络策略相关参数	
	- **AppGroup**：后台模式所用的GroupID，该选项只对Task有影响，默认为 `nil`
	- **isBackgroundSession**：是否为后台模式，该选项只对Task有影响，默认为 `NO`
	- **isErrorCodeDisplayEnabled**：出现网络请求错误时，是否在请求错误的文字后加上`{code}`，默认为YES
	- **cachePolicy**：请求缓存策略，默认为 `NSURLRequestUseProtocolCachePolicy`
	- **URLCache**：URLCache设置，默认为 `[NSURLCache sharedURLCache]`
- **defaultSecurityPolicy**：默认的安全策略配置，该配置在debug模式下默认为`HLSSLPinningModeNone`，release模式下默认为`HLSSLPinningModePublicKey`，其中详细参数如下：
	- **SSLPinningMode**：SSL Pinning证书的校验模式，默认为 `HLSSLPinningModeNone`
	- **allowInvalidCertificates**：是否允许使用Invalid 证书，默认为 `NO`
	- **validatesDomainName**：是否校验在证书 CN 字段中的 domain name，默认为 `YES`
	- **cerFilePath**：cer证书文件路径，默认为 `nil`
- **enableReachability**：是否启用reachability，baseURL为domain，默认为 `NO`
- **enableGlobalLog**：是否开启网络debug日志，该选项会在控制台输出所有网络回调日志，并且在Release模式下无效

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
    return [NSArray arrayWithObjects:self.api1, self.api2, self.api3, self.api4, nil];
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

**注意2：**一次请求必须有`{customURL}`或者`{config.baseURL | api.baseURL}``{api.path}`，如果`{customURL}`的参数错写成`{api.path}`中的无host urlString，也会被自动识别成`{api.path}`。

**注意3：**一个请求对象的回调 block (success/failure/progress/debug) 是非必需的（默认为 `nil`）。另外，需要注意的是，success/failure/debug等回调 Block 会在 config 设置的 `apiCallbackQueue ` 队列中被执行，但 progress 回调 Block 将在 NSURLSession 自己的队列中执行，而不是 `apiCallbackQueue `，但是所有的回调结果都会回落到主线程。

**注意4：**请求的delegate回调之所以这样设置，是为了可以跨类获取请求回调，因此使用起来稍微麻烦一些，如果只需要在当前类拿到回调，使用block方式即可。

**注意5：**HLAPI 同样支持其他 HTTP 方法，比如：`HEAD`, `DELETE`, `PUT`, `PATCH` 等，使用方式与上述类似，不再赘述。

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
HLNetworking 支持同时发一组批量请求，这组请求在业务逻辑上相关，但请求本身是互相独立的，请求时并行执行，`- apiGroupAllDidFinished` 会在所有请求都结束时才执行，每个请求的结果由API自身管理。注：`HLAPIGroup `类做了特殊处理，自身即为`HLAPI`的容器，因此直接`group[index]`即可获取相应的`HLAPI`对象，也可以直接遍历；回调中的 `apiGroup `中元素的顺序与每个无序请求 `HLAPI` 对象的先后顺序不保证一致。

```obc
HLAPIGroup *group = [HLAPIGroup groupWithMode:HLAPIGroupModeBatch];
// 添加单个api
[group add:[HLAPI API]];
// 添加apis集合
[group addAPIs:@[api1, api2, api3, nil]];

[group start];

batch.delegate = self;

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5), dispatch_get_main_queue(), ^{
	// 使用cancel取消
	[group cancel];
});

// group全部完成之后调用 
- (void)apiGroupAllDidFinished:(HLAPIGroup *)apiGroup {
    NSLog(@"%@", apiGroup);
}
```

#### 链式请求
HLNetworking 同样支持发一组链式请求，这组请求之间互相依赖，下一请求是否发送以及请求的参数可以取决于上一个请求的结果，请求时串行执行，`- chainRequestsAllDidFinished` 会在所有请求都结束时才执行，每个请求的结果由API自身管理。注：`HLAPIGroup `类做了特殊处理，自身即为`HLAPI`的容器，因此直接`group[index]`即可获取相应的`HLAPI`对象，也可以直接遍历；回调中的 `apiGroup `中元素的顺序与每个链式请求 `HLAPI` 对象的先后顺序一致。

```objc
HLAPIGroup *group = [HLAPIGroup groupWithMode:HLAPIGroupModeChian];
group.delegate = self;
// 设置每次发送几个请求，每次发出的请求之间无依赖
group.maxRequestCount = 1;
[group addAPIs:@[self.api1, self.api2, self.api3, self.api4, self.api5]];

[group start];

for (id obj in group) {
	NSLog(@"%@", obj);
}

HLAPI *api = group[0];

// group[0] == self.api1
NSLog(@"%@", api);

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5), dispatch_get_main_queue(), ^{
	// 使用cancel取消
	[group cancel];
});

// group全部完成之后调用 
- (void)apiGroupAllDidFinished:(HLAPIGroup *)apiGroup {
    NSLog(@"%@", apiGroup);
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
    return [NSArray arrayWithObjects:self.task1, nil];
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
### 批量上传/下载任务

#### 无序任务
HLNetworking 支持同时发一组批量上传/下载任务，这组请求在业务逻辑上相关，但请求本身是互相独立的，请求时并行执行，`- taskGroupAllDidFinished` 会在所有请求都结束时才执行，每个请求的结果由API自身管理。注：`HLTaskGroup `类做了特殊处理，自身即为`HLTask`的容器，因此直接`group[index]`即可获取相应的`HLAPI`对象，也可以直接遍历；回调中的 `taskGroup `中元素的顺序与每个无序请求 `HLAPI` 对象的先后顺序不保证一致。

```obc
HLTaskGroup *group = [HLTaskGroup groupWithMode:HLTaskGroupModeBatch];
group.delegate = self;
[group addTasks:self.taskArray];
[group start];

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5), dispatch_get_main_queue(), ^{
	// 使用cancel取消
	[group cancel];
});

// group全部完成之后调用 
- (void)apiGroupAllDidFinished:(HLAPIGroup *)apiGroup {
    NSLog(@"%@", apiGroup);
}
```

#### 链式任务
HLNetworking 同样支持发一组链式请求，这组请求之间互相依赖，下一请求是否发送以及请求的参数可以取决于上一个请求的结果，请求时串行执行，`- chainRequestsAllDidFinished` 会在所有请求都结束时才执行，每个请求的结果由API自身管理。注：`HLAPIGroup `类做了特殊处理，自身即为`HLAPI`的容器，因此直接`group[index]`即可获取相应的`HLAPI`对象，也可以直接遍历；回调中的 `apiGroup `中元素的顺序与每个链式请求 `HLAPI` 对象的先后顺序一致。

```objc
HLTaskGroup *group = [HLTaskGroup groupWithMode: HLTaskGroup ModeChian];
group.delegate = self;
// 设置每次发送几个请求，每次发出的请求之间无依赖
group.maxRequestCount = 1;
[group addTasks:@[self.task1, self.task2, self.task3, self.task4, self.task5]];
[group start];

for (id obj in group) {
	NSLog(@"%@", obj);
}

HLTask *task = group[0];

// group[0] == self.task1
NSLog(@"%@", api);

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5), dispatch_get_main_queue(), ^{
	// 使用cancel取消
	[group cancel];
});

// group全部完成之后调用 
- (void)apiGroupAllDidFinished:(HLAPIGroup *)apiGroup {
    NSLog(@"%@", apiGroup);
}
```

**注意1：**Task的resume信息记录在沙盒中`Cache/com.qkhl.HLNetworking/downloadDict中`。

### Center相关

- ``HLAPICenter``提供一种离散式API的组织模版，其核心理念是通过category分散APICenter内的API对象；
- ``HLBaseObjReformer``提供了基于YYModel的JSON->Model的模版；
- 通过``HLAPIMacro``中定义的宏，可以快速设置模块所需的API

#### 范例
- 根据API相关中的设置，配置HLAPIManager的相关Config
- 根据模块创建``HLAPICenter``的category，例如``HLAPICenter+home``
- 在HLAPICenter+home.h中使用HLStrongProperty(name)宏，name为方法名，形如：

```objc
#import "HLAPICenter.h"

@interface HLAPICenter (home)
HLStrongProperty(home)
@end
```

- 在HLAPICenter+home.m中使用HLStrongSynthesize(name, api)宏，name为方法名，api为API对象，形如：

```objc
#import "HLAPICenter+home.h"

@implementation HLAPICenter (home)
HLStrongSynthesize(home, [HLAPI API]
                   .setMethod(GET)
                   // 根据需要设置Path、BaseURL、CustomURL
                   .setPath(@"index.php?r=home")
                   // 如果该api对应的model可以直接通过yymodel转换的话，则指定需转换的模型类型名
                   .setResponseClass(@"HLHomeModel")
                   // 这里使用self.defaultReformer即通过yymodel转换
                   .setObjReformerDelegate(self.defaultReformer))
@end
```

- 然后就可以愉快的使用了，在控制器中```#import "HLAPICenter+home.h"```，按如下方法使用即可：

```objc
- (void)testHome {
    [HLAPICenter.home.setParams(@{@"user_id": @self.myUserID})
    .success(^(HLHomeModel *model) {
        self.model = model;
    }).failure(^(NSError *obj){
        NSLog(@"----%@", obj);
    }) start];
}
```

### Logger相关

- `HLNetworkLogger`提供了记录网络请求信息日志的功能，可自定义日志结构，日志头部信息，日志存储类型等

#### 配置Logger
可选参数如下：

- **channelID**：渠道ID
- **appKey**：app标志
- **appName**：app名字
- **appVersion**：app版本
- **serviceType**：服务名
- **enableLocalLog**：是否开启本地日志
- **logAutoSaveCount**：日志自动保存数，默认为50次保存一次
- **loggerLevel**：日志等级，该选项暂时无效
- **loggerType**：日志保存类型，可选JSON或者Plist
- **logFilePath**：只读，默认为`sandbox/Library/Cache/com.qkhl.HLNetworking/log/{timestamp}.log`

- 范例

```objc
[HLNetworkLogger setupConfig:^(HLNetworkLoggerConfig *config) {
    config.enableLocalLog = YES;
    config.logAutoSaveCount = 50;
    config.loggerType = HLNetworkLoggerTypeJSON;
}];
[HLNetworkLogger startLogging];

```

#### 默认Logger信息

- `HLNetworkLogger`默认提供的log信息为`HLDebugMessage`对象，包括:
	- `requestObject` api/task请求对象,
	- `sessionTask` NSURLSessionTask对象,
	- `response` HLURLResponse对象,
	- `queue` dispatch_queue_t对象，
	- 具体信息请参考`HLDebugMessage`，`HLURLResponse `，`HLURLResult`这三个文件中的注释
- `HLNetworkLogger`通过管理`debugInfoArray`数组来存储信息，该数组的首元素为当前APP信息，默认如下：
	- @{@"AppInfo": @{@"OSVersion": [UIDevice currentDevice].systemVersion,
		- @"DeviceType": [UIDevice currentDevice].hl_machineType,
		- @"UDID": [UIDevice currentDevice].hl_udid,
		- @"UUID": [UIDevice currentDevice].hl_uuid,
		- @"MacAddressMD5": [UIDevice currentDevice].hl_macaddressMD5,
		- @"ChannelID": _config.channelID,
		- @"AppKey": _config.appKey,
		- @"AppName": _config.appName,
		- @"AppVersion": _config.appVersion,
		- @"ServiceType": _config.serviceType}}


#### 自定义Logger信息

- `HLNetworkLogger`提供自定义log信息内容的方法，该方法每发一次请求，回调时都会调用一次:

```objc
// 设置当前类为logger代理，并将当前类遵守HLNetworkCustomLoggerDelegate协议
[HLNetworkLogger setDelegate:self];

// 根据传入的message信息和其他信息组装字典数据
- (NSDictionary *)customInfoWithMessage:(HLDebugMessage *)message {
    return [message toDictionary];
}

// 根据传入的config信息和其他信息组装字典
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
```

### 更新日志

**1.3.1**

```
修复：
1. 修复了HLNetworkLogger setDelegate方法调用错误的bug
2. 修复了HLTask缺少toDictionary方法的错误
```

**1.3.0**

```
新增：
1. HLNetworkLogger类，用于记录日志，控制台打印全局日志，本地日志记录，默认为50条请求保存一次，可自定义info和header代理
2. 网络链接不好的情况下自动重试的功能
3. HLAPIGroup类，统一chain和batch，通过构造方法的HLAPIGroupMode区分类型(chain, batch)，提供maxRequestCount属性，可以控制chainRequest每次的并行请求数，默认为1
4. HLTaskGroup，用法与HLAPIGroup一样，用于管理一组task请求
移除
1. chain和batch类
修复：
1. 修复了链式请求 请求重复时的线程调度问题
2. 修复了某些情况下并发请求会导致线程死锁的问题
3. 优化内部调用结构

```

**1.2.2**

```
新增：
1. 拆分了HLNetworkConfig内的参数，现分为tips、request、policy、defaultSecurityPolicy、enableReachability这五个大选项
修复：
1. 修复了HLObserverAPIs(...)和HLObserverTasks(...)内传入nil引起的崩溃错误
2. 修复了HLAPI中setResponseClass方法传入无效类名引起的崩溃错误，当该类名无效时，HLBaseObjReformer将不会做任何操作，直接返回nil
3. 修复了HLAPI中setCustomURL方法传入无效urlString引起的崩溃错误
```

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

     - HLNetworking/Core
     - HLNetworking/API
     - HLNetworking/Task
     - HLNetworking/Center

其中`Core`包含`API`和`Task`的所有代码，`API`和`Task`相互独立，`Center`则依赖于`API`


## 作者

wangshiyu13, wangshiyu13@163.com

## 开源协议

HLNetworking is available under the MIT license. See the LICENSE file for more info.
