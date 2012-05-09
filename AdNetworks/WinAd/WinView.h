//
//  WAdController.h
//  WinAdLib
//
//  Created by frank on 11-5-26.
//  Copyright 2011 www.winads.cn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "WinViewDelegateProtocol.h"

@class LoadWeb;

@interface WinView : UIView<MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIWebViewDelegate> {
	
@private
    //内部对象
	UIViewController    *controller;
	UIColor             *fontColor;
	NSString            *identity;
	NSString            *lat_long;
	NSDictionary        *infoBody;
	NSString            *randomCode;
	NSString            *netMode;
	NSUInteger           testMode;
	NSString            *p_id;
	NSString            *checkCode;
	NSString            *pStr;
	NSString            *Id;
	UIView              *contentView;
    LoadWeb             *webView;
	BOOL                 bHiddenTool;
	BOOL                 bLoading;
	
	NSString             *touchValue;
	//定义广告状态的通知协议的对象
	id <WinViewDelegate> delegate;
}


@property(nonatomic,retain)NSString               *touchValue;
@property(nonatomic,retain)UIColor                *fontColor;
@property(nonatomic,retain)NSString               *Id;
@property(nonatomic,retain)NSString               *identity;
@property(nonatomic,retain)NSString               *lat_long;
@property(nonatomic,retain)NSDictionary           *infoBody;
@property(nonatomic,retain)NSString               *randomCode;
@property(nonatomic,retain)NSString               *netMode;
@property                 NSUInteger               testMode;
@property(nonatomic,retain)NSString               *p_id;
@property(nonatomic,retain)NSString               *checkCode;
@property(nonatomic,retain)NSString               *pStr;

@property(nonatomic,retain)UIViewController*       controller;
@property (nonatomic, assign) id <WinViewDelegate> delegate;//声明广告状态的通知协议的对象为属性

//设置广告请求的刷新时间  默认为15秒
-(void)setRefreshInterval:(double)interval;
//设置广告的字体颜色 默认为白色
-(void)textColor:(UIColor*)color;
//设置广告条背景色，默认为黑色
-(void)normalBackgroundColor:(UIColor*)color;
//初始化广告条
- (id)initWithController:(UIViewController *)paramController;
/*
 *开始请求广告
 *
 *详解:入口函数，开始请求广告，当你设置完成后，务必记得调用该函数，以便通知后台开始请求服务器广告
 */
- (void)startRequestAd;
//停止请求广告
- (void)stopRequestAd;

- (void)recycleWithInterval:(double)interval;
- (void)backFromLoadWeb;


@end
