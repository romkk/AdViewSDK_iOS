//
//  File: AdMoGoAdapterAdwo.m
//  Project: AdsMOGO iOS SDK
//  Version: 1.0.6
//
//  Copyright 2011 AdsMogo.com. All rights reserved.
//

#import "AdViewAdapterIZP.h"
#import "AdViewView.h"
#import "AdViewViewImpl.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkConfig.h" 

@implementation AdViewAdapterIZP

+ (AdViewAdNetworkType)networkType {
	return AdViewAdNetworkTypeIZPTec;
}

+ (void)load {
    if (NSClassFromString(@"IZPView") != nil) {
        [[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];        
    }
}

- (void)getAd{
    NSString* apID = @"";
    Class izpViewClass = NSClassFromString(@"IZPView");
    if (izpViewClass == nil) {
        return;
    }

    if ([adViewDelegate respondsToSelector:@selector(izpApIDString)]) {
		apID = [adViewDelegate izpApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	
	[self updateSizeParameter];

    IZPView *adView = [[izpViewClass alloc] initWithFrame:self.rSizeAd];
    adView.productID = apID;
    adView.adType = @"1";
    adView.isDev = [adViewDelegate adViewTestMode];
    adView.delegate = self;
    [adView startAdExchange];
    
    self.adNetworkView = adView;
    [adView release];

    timer = [[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(loadAdTimeOut:) userInfo:nil repeats:NO] retain];
}

- (void)stopBeingDelegate {
    IZPView *adView = (IZPView *)self.adNetworkView;
    [adView stopAdExchange];
    if(adView != nil)
    {
        adView.delegate = nil;
    }
}

- (void)updateSizeParameter {
	BOOL isIPad = [AdViewAdNetworkAdapter helperIsIpad];
	
	AdviewBannerSize	sizeId = AdviewBannerSize_Auto;
	if ([adViewDelegate respondsToSelector:@selector(PreferBannerSize)]) {
		sizeId = [adViewDelegate PreferBannerSize];
	}
	
	if (sizeId > AdviewBannerSize_Auto) {
		switch (sizeId) {
			case AdviewBannerSize_320x50:
				self.rSizeAd = CGRectMake(0, 0, 320, 48);
				break;
			case AdviewBannerSize_300x250:
				self.rSizeAd = CGRectMake(0, 0, 320, 48);
				break;
			case AdviewBannerSize_480x60:
				self.rSizeAd = CGRectMake(0, 0, 320, 48);
				break;
			case AdviewBannerSize_728x90:
				self.rSizeAd = CGRectMake(0, 0, 768, 90);
				break;
		}
	} else if (isIPad) {
		self.rSizeAd = CGRectMake(0, 0, 768, 90);
	} else {
		self.rSizeAd = CGRectMake(0, 0, 320, 48);
	}
}

- (void)stopTimer {
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
}

- (void)dealloc {
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
	[super dealloc];
}


- (void)loadAdTimeOut:(NSTimer*)theTimer {
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    [self stopBeingDelegate];
    //[adViewView adapter:self didGetAd:@"izp"];
    [adViewView adapter:self didFailAd:nil];
}

/*
 *错误报告
 * 
 *详解:code 是错误代码  info是对错误的说明
 * 1：系统错误 2：参数错误 3：接口不存在 4：应用被冻结 5：无合适广告 6：应用用户不存在 7:请求广告时无法建立连接 8：请求广告时发生连接错误 9：解析广告出错  10 11 12 ：没能成功请求到广告资源  100：没有产品id  101:没有广告类型
 */
- (void) errorReport:(IZPView*)view  errorCode:(NSInteger)code erroInfo:(NSString*) info {
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    [view stopAdExchange];
    //[adViewView adapter:self didGetAd:@"izp"];
    [adViewView adapter:self didFailAd:nil];
}


/*
 *成功请求到一则广告
 *
 *详解:count代表请求到第几条广告，从1开始，累加计数
 */
- (void)didReceiveFreshAd:(IZPView*)view adCount:(NSInteger)count {
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    [view stopAdExchange];
    //[adViewView adapter:self didGetAd:@"izp"];
    [adViewView adapter:self didReceiveAdView:view];
}

/*
 请求广告失败
 
 详解:info 是错误代码，此时请求广告不会自动停止。-3:请求图片出错 -2:xml解析错误 -1：没能建立连接 
 */
- (void)didFailToReceiveFreshAd:(IZPView*)view errorInfo:(NSString*)info {
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    [view stopAdExchange];
    //[adViewView adapter:self didGetAd:@"izp"];
    [adViewView adapter:self didFailAd:nil];
}
 


/*用户停止贴片广告
 *
 *详解:在显示全屁贴片广告的时候，当用户点击了跳过按钮时候，调用此方法。此时广告请求已经停止，
 *
 */
- (void)didStopFullScreenAd:(IZPView*)view {
}



/*
 *
 *用户点击广告后将切换到浏览器
 *
 */

- (void)willLeaveApplication:(IZPView*)adView {

}
@end
