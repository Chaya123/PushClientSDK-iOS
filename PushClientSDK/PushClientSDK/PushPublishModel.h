//
//  PublishModel.h
//  PushClientSDK
//
//  Created by jeasonyoung on 2017/2/21.
//  Copyright © 2017年 Murphy. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 推送弹出消息数据。
 **/
@interface PushPublishAlertModel : NSObject

/**
 * @brief 弹出消息内容。
 **/
@property(copy,nonatomic,readonly)NSString *body;

@property(copy,nonatomic,readonly)NSString *actionLocKey;

@property(copy,nonatomic,readonly)NSString *locKey;

/**
 * @brief 弹出图片。
 **/
@property(copy,nonatomic,readonly)NSString *launchImage;
/**
 * @brief 参数。
 **/
@property(copy,nonatomic,readonly)NSArray *locArgs;

/**
 * @brief 初始化创建对象。
 * @param alert 字典数据。
 * @return 对象实例。
 **/
-(instancetype)initWithAlertData:(NSDictionary *)alert;

@end

/**
 * @brief Apns消息格式
 **/
@interface PushPublishApnsModel : NSObject

/**
 * @brief 弹出数据格式。
 **/
@property(retain, nonatomic,readonly)id alert;
/**
 * @brief App右上角数字。
 **/
@property(assign,nonatomic,readonly)NSInteger badge;
/**
 * @brief sound。
 **/
@property(copy,nonatomic,readonly)NSString *sound;

@property(assign,nonatomic,readonly)NSInteger contentAvailable;

/**
 * @brief 初始化对象。
 * @param apns 数据字典。
 * @return 返回对象。
 **/
-(instancetype)initWithApnsData:(NSDictionary *)apns;

@end

/**
 * @brief 推送消息数据。
 **/
@interface PushPublishModel : NSObject

/**
 * @brief apns消息格式。
 **/
@property(retain,nonatomic,readonly)PushPublishApnsModel *apns;
/**
 * @brief 推送消息ID。
 **/
@property(copy,nonatomic,readonly)NSString *pushId;
/**
 * @brief 推送消息内容ID。
 **/
@property(copy,nonatomic,readonly)NSString *contentId;
/**
 * @brief 推送消息内容。
 **/
@property(copy,nonatomic,readonly)NSString *content;

/**
 * @brief 初始化数据。
 * @param data 数据字典。
 * @return 推送数据对象。
 **/
-(instancetype)initWithData:(NSDictionary *)data;

/**
 * @brief 根据JSON数据静态创建对象。
 * @param json 推送JSON数据。
 * @return 推送数据对象。
 **/
+(instancetype)publishWithJSON:(NSString *)json;
@end
