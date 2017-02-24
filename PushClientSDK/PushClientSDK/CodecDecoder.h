//
//  CodecDecoder.h
//  PushClientSDK
//
//  Created by jeasonyoung on 2017/2/24.
//  Copyright © 2017年 Murphy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Codec.h"

/**
 * @brief socket消息解码器委托。
 **/
@protocol CodecDecoderDelegate <NSObject>

/**
 * @brief 解码数据处理。
 * @param type 消息类型。
 * @param model 解码后的消息模型数据对象。
 **/
-(void)decoderWithType:(PushSocketMessageType)type andAckModel:(id)model;

@end

/**
 * @brief socket消息解码器。
 **/
@interface CodecDecoder : Codec
/**
 * @brief 获取或设置消息解码器委托。
 **/
@property(assign, nonatomic)id<CodecDecoderDelegate> delegate;

/**
 * @brief 添加需解码的数据。
 * @param source 需解码的源数据。
 **/
-(void)decoderWithAppendData:(NSData *)source;

@end
