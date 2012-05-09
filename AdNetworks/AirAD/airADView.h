//
//  airADBannerView.h
//  airADKit
//
//  Created by NSXiu on 10/24/11.
//  Copyright 2011 MitianTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "airADViewDelegate.h"

#pragma mark -
#pragma mark Ad Size

#define AD_SIZE_320x54     CGSizeMake(320, 54)

typedef enum refreshMode {
  REFRESH_MODE_AUTO,
  REFRESH_MODE_MANUAL,
}ADRefreshMode;

typedef enum GPSMode {
  GPS_ON,
  GPS_OFF,
}GPSMode;

typedef enum bannerBGMode {
  BannerBG_ON,
  BannerBG_OFF,
}BannerBGMode;

typedef enum debugMode {
  DEBUG_ON,
  DEBUG_OFF,
}DebugMode;

@interface airADView : UIView
@property (nonatomic, assign) id<airADViewDelegate> delegate;

//设定手动刷新时,可使用此方法.
//最短间隔15秒使用一次.
- (void)refreshAd;

//设置ADRefreshMode可以设置当前BannerView的刷新方式.您可以选择方便的REFRESH_MODE_AUTO
//模式,这样BannerView内的广告会自动定时刷新.您也可以选择REFRESH_MODE_MANUAL模式,手动
//控制当前BannerView的广告内容刷新状态.
//默认: REFRESH_MODE_AUTO
- (void)setRefreshMode:(ADRefreshMode)mode;

//设置BannerBGMode可以主动选择,是否需要显示BannerView的背景.
//默认:BannerBG_ON
- (void)setBannerBGMode:(BannerBGMode)mode;

//设置IntervalTime主要影响REFRESH_MODE_AUTO时,广告刷新的周期.
//最小值为15.
//默认:15
- (void)setIntervalTime:(NSTimeInterval)interval;

@end

@interface airADView(ParameterMethods)

//设置AppId(可从登陆www.airad.com,创建新应用程序获得).
//一个应用程序只能设置也只会使用一个appId.
+ (void)setAppID:(NSString *)appId;

//你可以通过设置GPSMode来选择是否需要开启GPS模式.
//GPS的开启会帮助我们为您的应用提供更为精确的广告,这会对提高您的收益有很大的帮助.
//默认:GPS_ON
+ (void)setGPSMode:(GPSMode)mode;

//为开发者提供方便的调试模式,时刻监控当前广告运作情况.
//默认:DEBUG_Off
+ (void)setDebugMode:(DebugMode)mode;

@end