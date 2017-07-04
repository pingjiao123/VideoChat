//
//  NetworkManager.h
//  xfjStore
//
//  Created by ZhangQiang on 2017/1/5.
//  Copyright © 2017年 xlb. All rights reserved.
//

typedef NS_ENUM(NSInteger, NetworkReachabilityStatus) {
    NetworkReachabilityStatusUnknown          = -1,
    NetworkReachabilityStatusNotReachable     = 0,
    NetworkReachabilityStatusReachableViaWWAN = 1,
    NetworkReachabilityStatusReachableViaWiFi = 2,
};

typedef NS_ENUM(NSUInteger, RequestSerializer) {
    /** 设置请求数据为JSON格式*/
    RequestSerializerJSON,
    /** 设置请求数据为二进制格式*/
    RequestSerializerHTTP,
};

typedef NS_ENUM(NSUInteger, ResponseSerializer) {
    /** 设置响应数据为JSON格式*/
    ResponseSerializerJSON,
    /** 设置响应数据为二进制格式*/
    ResponseSerializerHTTP,
};

@protocol AFMultipartFormData;
@interface NetworkResponse : NSObject <NSCoding>

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *code;
@property (nonatomic, strong) id content;

- (BOOL)isSucceed;

@end

/** 请求成功的Block */
typedef void(^HttpRequestSuccess)(NetworkResponse *responseObject);

/** 请求失败的Block */
typedef void(^HttpRequestFailed)(NSError *error);

/** 缓存的Block */
typedef void(^HttpRequestCache)(NetworkResponse *responseCache);

@interface NetworkManager : NSObject

// 网络状态监测
+ (NetworkReachabilityStatus)networkReachabilityStatus;

+ (void)startMonitoring;

+ (void)setReachabilityStatusChangeBlock:(nullable void (^)(NetworkReachabilityStatus status))block;

/**
 有网YES, 无网:NO
 */
+ (BOOL)hasNetwork;

/**
 手机网络:YES, 反之:NO
 */
+ (BOOL)isWWANNetwork;

/**
 WiFi网络:YES, 反之:NO
 */
+ (BOOL)isWiFiNetwork;

/**
 取消所有HTTP请求
 */
+ (void)cancelAllRequest;

/**
 取消指定URL的HTTP请求
 */
+ (void)cancelRequestWithURL:(NSString *)URL;

/**
 *  GET请求,无缓存
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                           success:(HttpRequestSuccess)success
                           failure:(HttpRequestFailed)failure;

/**
 *  GET请求,自动缓存
 *
 *  @param URL           请求地址
 *  @param parameters    请求参数
 *  @param responseCache 缓存数据的回调
 *  @param success       请求成功的回调
 *  @param failure       请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                     responseCache:(HttpRequestCache)responseCache
                           success:(HttpRequestSuccess)success
                           failure:(HttpRequestFailed)failure;

/**
 *  POST请求,无缓存
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                            success:(HttpRequestSuccess)success
                            failure:(HttpRequestFailed)failure;

/**
 *  POST请求,自动缓存
 *
 *  @param URL           请求地址
 *  @param parameters    请求参数
 *  @param responseCache 缓存数据的回调
 *  @param success       请求成功的回调
 *  @param failure       请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                      responseCache:(HttpRequestCache)responseCache
                            success:(HttpRequestSuccess)success
                            failure:(HttpRequestFailed)failure;


/**
 *  POST 上传文件
 *
 *  @param urlString           请求路径
 *  @param parameters          请求参数 将自动添加Token
 *  @param block               formData 上传文件时使用
 *  @param uploadProgressBlock 上传进程
 *  @param success             成功处理
 *  @param failure             失败处理
 */
+ (NSURLSessionDataTask *)post:(NSString *)urlString
                    parameters:(NSDictionary *)parameters
     constructingBodyWithBlock:(void (^) (id<AFMultipartFormData> formData))block
                      progress:(void (^)(NSProgress *progress))uploadProgressBlock
                       success:(HttpRequestSuccess)success
                       failure:(HttpRequestFailed)failure;

/**
 *  POST 上传图片数组
 *
 *  @param urlString           请求路径
 *  @param parameters          请求参数 将自动添加Token
 *  @param images              图片数组
 *  @param uploadProgressBlock 上传进程
 *  @param success             成功处理
 *  @param failure             失败处理
 */
+ (NSURLSessionDataTask *)post:(NSString *)urlString
                    parameters:(NSDictionary *)parameters
                        images:(NSArray<UIImage *> *)images
                      progress:(void (^)(NSProgress *progress))uploadProgressBlock
                       success:(HttpRequestSuccess)success
                       failure:(HttpRequestFailed)failure;

#pragma mark - 重置AFHTTPSessionManager相关属性
/**
 *  设置网络请求参数的格式:默认为JSON格式
 *
 *  @param requestSerializer PPRequestSerializerJSON(JSON格式),PPRequestSerializerHTTP(二进制格式),
 */
+ (void)setRequestSerializer:(RequestSerializer)requestSerializer;

/**
 *  设置服务器响应数据格式:默认为JSON格式
 *
 *  @param responseSerializer PPResponseSerializerJSON(JSON格式),PPResponseSerializerHTTP(二进制格式)
 */
+ (void)setResponseSerializer:(ResponseSerializer)responseSerializer;

/**
 *  设置请求超时时间:默认为30S
 *
 *  @param time 时长
 */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;

/**
 *  设置请求头
 */
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 *  是否打开网络状态转圈菊花:默认打开
 *
 *  @param open YES(打开), NO(关闭)
 */
+ (void)openNetworkActivityIndicator:(BOOL)open;

/**
 配置自建证书的Https请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103
 
 @param cerPath 自建Https证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO; 即服务器使用其他可信任机构颁发
 的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName=NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外
 一个域名。因为SSL证书上的域名是独立的,假如证书上注册的域名是www.google.com, 那么mail.google.com是无法验证通过的.
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;


@end
