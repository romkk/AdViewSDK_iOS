//
//  WinViewDelegateProtocol.h
//  WinAdLib
//
//  Created by Mac on 11-10-28.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

@class WinView;
//定义协议
@protocol WinViewDelegate <NSObject>

@optional

#pragma mark Ad Request Notification Methods

// 请求广告条数据成功后调用
//
// 详解:当接收服务器返回的广告数据成功后调用该函数
// 补充：第一次返回成功数据后调用
-(void)WinAdDidLoad;


// 请求广告条数据失败后调用
// 
// 详解:当接收服务器返回的广告数据失败后调用该函数
// 补充：第一次和接下来每次如果请求失败都会调用该函数
-(void)WinAdDidFailLoad;

@required

/*
 *开发者应用ID
 *
 *详解:前往赢告主页:http://www.winads.cn/ 注册一个开发者帐户，同时注册一个应用，获取对应应用的ID
 */
- (NSString *)WinAdDevId:(WinView *)adView;

/*
 *广告请求模式
 *
 *详解:广告请求的模式 [0：正常模式 1：测试模式 非法：测试模式] 
 *正常模式:按正常广告请求，记录展示和点击结果
 *测试模式:开始测试情况下请求，不记录展示和点击结果
 *备注:默认是模拟器是测试模式真机是正常模式，若开发者在模拟器上面使用的时候，无论返回的是0，还是1都被默认为测试模式
 *	  开发者只有在真机器模式下面才返回0，正常模式才有效
 *警告:若设置了正常模式，则若请求过快，或者点击过快过多则都有可能被服务器判为作弊行为，停止广告的请求。测试模式下没有这种限制。
 */
- (NSUInteger)WinAdTestMode:(WinView *)adView;

@end