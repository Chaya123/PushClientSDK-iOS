//
//  PushClientSDK.m
//  PushClientSDK
//
//  Created by jeasonyoung on 2017/2/8.
//  Copyright © 2017年 Murphy. All rights reserved.
//

#import "PushClientSDK.h"

#import "AFNetworking.h"


#import "PushAccessData.h"
#import "PushRequestData.h"
#import "PushSocket.h"

static NSString * const PUSH_SRV_URL_PREFIX = @"http";
static NSString * const PUSH_SRV_URL_SUFFIX = @"/push-http-connect/v1/callback/connect.do";

//构造函数
@interface PushClientSDK ()<PushSocketHandlerDelegate>{
    PushAccessData *_accessData;
    PushSocket *_socket;
}
@end

//实现
@implementation PushClientSDK

#pragma mark -- 单例
+(instancetype)sharedInstance{
    static PushClientSDK *_instance;
    //
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[PushClientSDK alloc] init];
    });
    return _instance;
}

#pragma mark -- 初始化。
-(instancetype)init{
    if(self = [super init]){
        _accessData = [PushAccessData sharedAccess];//初始化访问数据
        _socket = [PushSocket shareSocket];//初始化socket处理
        _socket.delegate = self;
    }
    return self;
}

#pragma mark -- 公开方法

#pragma mark -- 启动推送
-(void)startHost:(NSString *)host
      andAccount:(NSString *)account
     andPassword:(NSString *)pwd
 withDeviceToken:(NSData *)token{
    //检查host
    if(!host || !host.length){
        @throw [NSException exceptionWithName:@"host" reason:@"服务器(host)不能为空!" userInfo:nil];
    }
    //
    NSMutableString *url = [NSMutableString string];
    //检查前部
    if(![host hasPrefix:PUSH_SRV_URL_PREFIX]){
        [url appendFormat:@"%@://", PUSH_SRV_URL_PREFIX];
    }
    //检查尾部
    NSRange range = [host rangeOfString:PUSH_SRV_URL_SUFFIX];
    if(range.location != NSNotFound){
        @throw [NSException exceptionWithName:@"host" reason:@"服务器(host)不需要包含子路径!" userInfo:nil];
    }
    if([host hasSuffix:@"/"]){
        [url appendString:[host substringToIndex:(host.length - 1)]];
    }else{
        [url appendString:host];
    }
    [url appendString:PUSH_SRV_URL_SUFFIX];
    NSLog(@"url:%@", url);
    //检查接入帐号
    if(!account || !account.length) @throw [NSException exceptionWithName:@"account" reason:@"接入帐号(account)不能为空!" userInfo:nil];
    //检查接入密码
    if(!pwd || !pwd.length) @throw [NSException exceptionWithName:@"pwd" reason:@"接入密钥(password)不能为空!" userInfo:nil];
    //检查设备令牌
    if(!token || !token.length) @throw [NSException exceptionWithName:@"token" reason:@"设备令牌(token)不能为空!" userInfo:nil];
    //初始化数据
    [_accessData initialWithURL:url andAccount:account andPassword:pwd andDeviceToken:token];
    //访问HTTP服务器
    [self accessHttpServer];
}

#pragma mark -- 添加或更改用户标签
-(void)addOrChangedTag:(NSString *)tag{
    NSLog(@"addOrChangedTag=>%@", tag);
    if(!tag || !tag.length) return;
    [_accessData addOrUpdateDeviceUserWithTag:tag];
    if(_socket){
        [_socket addOrChangedTagHandler];
    }
}

#pragma mark -- 清除用户标签
-(void)clearTag{
    NSLog(@"clear...");
    [_accessData addOrUpdateDeviceUserWithTag:nil];
    if(_socket){
        [_socket clearTagHandler];
    }
}

#pragma mark -- 关闭推送客户端
-(void)close{
    NSLog(@"close...");
    [self stopSocketClient];
}


#pragma mark -- 接收远程推送消息。
-(void)receiveRemoteNotification:(NSDictionary *)userInfo{
    if(!userInfo || !userInfo.count) return;
    PushPublishModel *model = [[PushPublishModel alloc] initWithData:userInfo];
    [self pushwithPublish:model];
}

#pragma mark -- 内部方法。

#pragma mark -- 访问HTTP服务器获取配置
-(void)accessHttpServer{
    //构建参数集合
    NSDictionary *params = [[[PushRequestData alloc] initWithAccess:_accessData] toSignParameters];
    //网络请求处理
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    AFJSONResponseSerializer *jsonResponseSerializer = [AFJSONResponseSerializer serializer];
    jsonResponseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                                          @"text/json",
                                                                          @"text/javascript",
                                                                          @"text/html",nil];
    manager.responseSerializer = jsonResponseSerializer;
    [manager POST:_accessData.url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"获取推送socket服务器数据成功:%@", responseObject);
        NSInteger result  = [responseObject[@"result"] integerValue];
        if(result == 0){//获取Socket服务器配置成功
            NSDictionary *dict = responseObject[@"setting"];
            NSLog(@"socket-settings=>%@", dict);
            [_accessData addOrUpdateConfigWithSocket:dict];
            [self startSocketClient];
        }else{
            NSString *message = responseObject[@"message"];
            [self sendErrorWithType:PushClientSDKErrorTypeSrvConf message:[NSString stringWithFormat:@"%zd-%@", result, message]];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"网络异常=>%@", error);
        [self sendErrorWithType:PushClientSDKErrorTypeConnect message:error.localizedDescription];
    }];
}

#pragma mark -- 启动socket客户端
-(void)startSocketClient{
    NSLog(@"startSocketClient...");
    if(!_socket.delegate){
        _socket.delegate = self;
    }
    //启动
    [_socket start];
}

#pragma mark -- 关闭socket客户端
-(void)stopSocketClient{
    NSLog(@"stopSocketClient...");
    if(_socket){
        [_socket stop];
    }
}

#pragma mark -- 抛出推送消息
-(void)pushwithPublish:(PushPublishModel *)publish{
    if(!publish)return;
    if(self.delegate && [self.delegate respondsToSelector:@selector(pushClientSDK:withIsApns:receivePushMessageTitle:andMessageContent:withFullPublish:)]){
        NSString *title = nil;
        id alert = publish.apns ? publish.apns.alert : nil;
        if(alert && [alert isKindOfClass:[NSString class]]){
            title = (NSString *)alert;
        }else if(alert && [alert isKindOfClass:[PushPublishAlertModel class]]){
            title = ((PushPublishAlertModel *)alert).body;
        }
        [self.delegate pushClientSDK:self
                          withIsApns:NO
             receivePushMessageTitle:title
                   andMessageContent:publish.content
                     withFullPublish:publish];
    }
}

#pragma mark -- socket delegate

#pragma mark -- 获取socket配置数据
-(void)pushSocket:(PushSocket *)socket withAccessConfig:(PushAccessData *__autoreleasing *)config{
    NSLog(@"pushSocket:%@,withSocketConfig:%@", socket, *config);
    if(_accessData && _accessData.socket){
        *config = _accessData;
    }
}

#pragma mark -- 异常消息处理
-(void)pushSocket:(PushSocket *)socket withMessageType:(PushSocketMessageType)type throwsError:(NSError *)error{
    NSLog(@"pushSocket:%@,type:%zd,error:%@", socket, type, error);
    [self sendErrorWithType:PushClientSDKErrorTypeConnect message:error.description];
}

#pragma mark -- 推送消息处理
-(void)pushSocket:(PushSocket *)socket withPublish:(PushPublishModel *)publish{
    [self pushwithPublish:publish];
}

#pragma mark -- 重新连接处理
-(void)pushSocket:(PushSocket *)socket withStartReconnect:(BOOL)reconnect{
    NSLog(@"重新连接=>%d", reconnect);
    if(reconnect){
        NSLog(@"开始重新请求HTTP...");
        [self accessHttpServer];
    }else{
        [self startSocketClient];
    }
}

#pragma mark -- 发送错误消息处理
-(void)sendErrorWithType:(PushClientSDKErrorType)type message:(NSString *)msg{
    NSLog(@"发生错误异常(%zd):%@", type, msg);
    if(self.delegate && [self.delegate respondsToSelector:@selector(pushClientSDK:withErrorType:andMessageDesc:)]){
        [self.delegate pushClientSDK:self withErrorType:type andMessageDesc:msg];
    }
}

@end
