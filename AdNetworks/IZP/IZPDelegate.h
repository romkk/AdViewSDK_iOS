//
//  IZPDelegate.h
//  TestADExchange
//
//  Created by quan zheng on 11-5-10.
//  Copyright 2011年 Jinuoxun Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class IZPView;

@protocol IZPDelegate <NSObject>
@optional
/*
 *错误报告
 * 
 *详解:code 是错误代码  info是对错误的说明
 * 1：系统错误 2：参数错误 3：接口不存在 4：应用被冻结 5：无合适广告 6：应用用户不存在 7:请求广告时无法建立连接 8：请求广告时发生连接错误 9：解析广告出错  10 11 12 ：没能成功请求到广告资源  100：没有产品id  101:没有广告类型
 */
- (void) errorReport:(IZPView*)view  errorCode:(NSInteger)code erroInfo:(NSString*) info;


/* 是否请求一条广告
 *
 * 详解：默认是请求一条广告，如果返回是fasle 则不请求广告，SDK会定时调用该函数
 */
-(BOOL)shouldRequsetFreshAd:(IZPView*)view;

/* 是否显示请求到的广告
 *
 * 详解：默认是显示，如果返回是fasle 则不显示，SDK会定时调用该函数
 */
-(BOOL)shouldShowFreshAd:(IZPView*)view;

/*
 *成功请求到一则广告
 *
 *详解:count代表请求到第几条广告，从1开始，累加计数
 */
- (void)didReceiveFreshAd:(IZPView*)view adCount:(NSInteger)count;

/*
请求广告失败

详解:info 是错误代码，此时请求广告不会自动停止。-3:请求图片出错 -2:xml解析错误 -1：没能建立连接 

/
- (void)didFailToReceiveFreshAd:(IZPView*)view errorInfo:(NSString*)info;
*/


/*用户停止贴片广告
 *
 *详解:在显示全屁贴片广告的时候，当用户点击了跳过按钮时候，调用此方法。此时广告请求已经停止，
 *
 */
- (void)didStopFullScreenAd:(IZPView*)view;



/*
 *
 *用户点击广告后将切换到浏览器
 *
 */

- (void)willLeaveApplication:(IZPView*)adView;

@end
