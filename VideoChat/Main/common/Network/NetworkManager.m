//
//  NetworkManager.m
//  xfjStore
//
//  Created by ZhangQiang on 2017/1/5.
//  Copyright © 2017年 xlb. All rights reserved.
//

#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#define kJavaBaseURL @"jiaoping"

#import "NetworkManager.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import "HttpCache.h"
#import <YYCategories/YYCategories.h>
#import <MJExtension/MJExtension.h>

@implementation NetworkResponse

- (BOOL)isSucceed {
    return [self.code isEqualToString:@"1"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.message = [aDecoder decodeObjectForKey:@"message"];
        self.code = [aDecoder decodeObjectForKey:@"code"];
        self.content = [aDecoder decodeObjectForKey:@"content"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.message forKey:@"message"];
    [aCoder encodeObject:self.code forKey:@"code"];
    [aCoder encodeObject:self.content forKey:@"content"];
}
@end

@implementation NetworkManager

static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;

+ (void)initialize {
    NSURL *baseURL = [NSURL URLWithString:kJavaBaseURL];
    _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    // 设置请求的超时时间
    _sessionManager.requestSerializer.timeoutInterval = 30.f;
    // 设置服务器返回结果的类型:JSON (AFJSONResponseSerializer,AFHTTPResponseSerializer)
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    // 打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

+ (NetworkReachabilityStatus)networkReachabilityStatus {
    return (NetworkReachabilityStatus)[AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
}

+ (void)setReachabilityStatusChangeBlock:(nullable void (^)(NetworkReachabilityStatus status))block {
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        block((NetworkReachabilityStatus)status);
    }];
}

+ (void)startMonitoring {
    return [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (BOOL)hasNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

#pragma mark - 取消请求

+ (void)cancelAllRequest {
    // 锁操作
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL) { return; }
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}

#pragma mark - GET请求无缓存

+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure {
    return [self GET:URL parameters:parameters responseCache:nil success:success failure:failure];
}


#pragma mark - POST请求无缓存

+ (NSURLSessionTask *)POST:(NSString *)URL
                parameters:(NSDictionary *)parameters
                   success:(HttpRequestSuccess)success
                   failure:(HttpRequestFailed)failure {
    return [self POST:URL parameters:parameters responseCache:nil success:success failure:failure];
}


#pragma mark - GET请求自动缓存

+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
            responseCache:(HttpRequestCache)responseCache
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure {
    responseCache ? [HttpCache httpCacheForURL:URL parameters:parameters withBlock:responseCache] : nil;
    NSURLSessionTask *sessionTask = [_sessionManager GET:URL parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        DLog(@"responseObject = %@",[self jsonToString:responseObject]);
        NetworkResponse *response = [NetworkResponse mj_objectWithKeyValues:responseObject];
        if ([response isSucceed]) {
            success ? success(response) : nil;
            responseCache ? [HttpCache setHttpCache:response URL:URL parameters:parameters] : nil;
        } else {
            NSString *message = response.message;
            if ([response.message isNotBlank]) {
                if ([response.message containsString:@"接口异常"]) {
                    message = @"服务器打了个盹";
                }
            } else {
                message = @"未知原因";
            }
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:response.code.integerValue userInfo:@{NSLocalizedDescriptionKey:message, NSURLErrorFailingURLErrorKey:URL}];
            failure ? failure(error) : nil;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        DLog(@"error = %@",error);
        failure ? failure(error) : nil;
    }];
    return sessionTask;
}

#pragma mark - POST请求自动缓存

+ (NSURLSessionTask *)POST:(NSString *)URL
                parameters:(NSDictionary *)parameters
             responseCache:(HttpRequestCache)responseCache
                   success:(HttpRequestSuccess)success
                   failure:(HttpRequestFailed)failure {
    responseCache ? [HttpCache httpCacheForURL:URL parameters:parameters withBlock:responseCache] : nil;
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        DLog(@"responseObject = %@",[self jsonToString:responseObject]);
        NetworkResponse *response = [NetworkResponse mj_objectWithKeyValues:responseObject];
        if ([response isSucceed]) {
            success ? success(response) : nil;
            responseCache ? [HttpCache setHttpCache:response URL:URL parameters:parameters] : nil;
        } else {
            NSString *message = response.message;
            if ([response.message isNotBlank]) {
                if ([response.message containsString:@"接口异常"]) {
                    message = @"服务器打了个盹";
                }
            } else {
                message = @"未知原因";
            }
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:response.code.integerValue userInfo:@{NSLocalizedDescriptionKey:message, NSURLErrorFailingURLErrorKey:URL}];
            failure ? failure(error) : nil;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        DLog(@"error = %@",error);
        failure ? failure(error) : nil;
    }];
    return sessionTask;
}

+ (NSString *)jsonToString:(id)data {
    if(!data) { return nil; }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/**
 *  添加Token
 */
- (NSDictionary *)p_addTokenWithParameters:(NSDictionary *)parameters {
    NSMutableDictionary *para = [parameters mutableCopy];
#warning 替换掉
    NSString *token = @"";
    if (token.length > 1) {
        para[@"Token"] = token;
        NSLog(@"%@",token);
    }
    return para.copy;
}

#pragma mark - 上传文件
+ (NSURLSessionDataTask *)post:(NSString *)urlString
                    parameters:(NSDictionary *)parameters
     constructingBodyWithBlock:(void (^) (id<AFMultipartFormData>  _Nonnull formData))block
                      progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgressBlock
                       success:(HttpRequestSuccess)success
                       failure:(HttpRequestFailed)failure {
    
//    NSDictionary *para = [self p_addTokenWithParameters:parameters];
    
    AFHTTPResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
    _sessionManager.responseSerializer = responseSerializer;
    
    return [_sessionManager POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        if (block) {
            block(formData);
        }
    } progress:uploadProgressBlock success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            NetworkResponse *model =  [NetworkResponse mj_objectWithKeyValues:responseObject];
            success(model);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - 上传图片数组
+ (NSURLSessionDataTask *)post:(NSString *)urlString
                    parameters:(NSDictionary *)parameters
                        images:(NSArray<UIImage *> *)images
                      progress:(void (^)(NSProgress *progress))uploadProgressBlock
                       success:(HttpRequestSuccess)success
                       failure:(HttpRequestFailed)failure {
    
    return [self post:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        static NSDateFormatter *formatter;
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
        }
        
        for (UIImage *image in images) {
            NSData *imageData = UIImageJPEGRepresentation(image, 1);
            if (imageData) {
                NSString *str = [formatter stringFromDate:[NSDate date]];
                NSString *fileName = [NSString stringWithFormat:@"%@.jpg", str];
                [formData appendPartWithFileData:imageData name:@"files" fileName:fileName mimeType:@"image/jpeg"];
            }
        }
        
    } progress:uploadProgressBlock success:success failure:failure];
}


#pragma mark - 重置AFHTTPSessionManager相关属性
+ (void)setRequestSerializer:(RequestSerializer)requestSerializer {
    _sessionManager.requestSerializer = requestSerializer == RequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)setResponseSerializer:(ResponseSerializer)responseSerializer {
    _sessionManager.responseSerializer = responseSerializer == ResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time {
    _sessionManager.requestSerializer.timeoutInterval = time;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

+ (void)openNetworkActivityIndicator:(BOOL)open {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}

+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 如果需要验证自建证书(无效证书)，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    [_sessionManager setSecurityPolicy:securityPolicy];
}

@end

#pragma mark - NSDictionary,NSArray的分类
/*
 ************************************************************************************
 *NSDictionary与NSArray的分类, 控制台打印json数据中的中文
 ************************************************************************************
 */

#ifdef DEBUG
@implementation NSArray (Network)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [strM appendFormat:@"\t%@,\n", obj];
    }];
    [strM appendString:@")"];
    return strM;
}

@end

@implementation NSDictionary (Network)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [strM appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    [strM appendString:@"}\n"];
    return strM;
}
@end
#endif
