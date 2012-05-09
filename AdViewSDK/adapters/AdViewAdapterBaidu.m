/*
 adview casee.
*/

#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewAdapterBaidu.h"

#define NEED_IN_REALVIEW	0

static	BOOL	hasGotBaiduAd = NO;

@interface AdViewAdapterBaidu ()
@end


@implementation AdViewAdapterBaidu

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeBAIDU;
}

+ (void)load {
	if(NSClassFromString(@"BaiduMobAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

+ (CGRect)adRect {
	return CGRectMake(0, 0, 320, 48);
}

- (void)getAd {
	Class baiduViewClass = NSClassFromString (@"BaiduMobAdView");
	
	AWLogInfo(@"baidu getAd");
	
	if (nil == baiduViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no domob lib, can not create.");
		return;
	}
	[self updateSizeParameter];
    BaiduMobAdView* sharedAdView = [baiduViewClass sharedAdViewWithDelegate:self];
//	NSString *typeStr = networkConfig.pubId3;
//	int type = [typeStr intValue];
//	if (2 == type) sharedAdView.AdType = BaiduMobAdViewTypeText;
//	else 
		sharedAdView.AdType = BaiduMobAdViewTypeImage;	//type by config.
	
#if NEED_IN_REALVIEW
	if ([adViewDelegate respondsToSelector:@selector(viewControllerForPresentingModalView)])
	{
		UIViewController *controller = [adViewDelegate viewControllerForPresentingModalView];
		if (nil != controller && nil != controller.view)
		{
			[controller.view addSubview:sharedAdView];
			sharedAdView.frame = [AdViewAdapterBaidu adRect];
			sharedAdView.hidden = YES;
		}
	}
#endif
	UIColor *txtColor = [self helperTextColorToUse];
	sharedAdView.textColor = txtColor;
	
	self.adNetworkView = sharedAdView;
	
	if (hasGotBaiduAd) {//因为baidu的实际取广告时间无法控制。
		sharedAdView.hidden = NO;
		sharedAdView.frame = [AdViewAdapterBaidu adRect];
		[adViewView adapter:self shouldAddAdView:sharedAdView]; 
		//shouldAddAdView won't add show number.
	}
}

- (void)stopBeingDelegate {
  BaiduMobAdView *adView = (BaiduMobAdView *)adNetworkView;
	AWLogInfo(@"--stopBeingDelegate--结束--");
  if (adView != nil) {
	  if (adView.delegate == self) {
		  [adView removeFromSuperview];
		  adView.delegate = nil;
	  }
	  self.adNetworkView = nil;	//empty it.
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
				self.nSizeAd = 0;
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = 0;
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = 0;
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = 0;
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = 0;
	} else {
		self.nSizeAd = 0;
	}
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark BaiduDelegate methods

- (NSString *)publisherId {
	NSString *apID;
	if ([networkConfig.pubId length] > 0 && ![networkConfig.pubId isEqualToString:@"baidu"]) {
		apID = networkConfig.pubId;
	}
	else if ([adViewDelegate respondsToSelector:@selector(BaiDuApIDString)]) {
		apID = [adViewDelegate BaiDuApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
    
    if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)]
        && [adViewDelegate adViewTestMode] == YES) {
        return @"debug";
    }
    
	return apID;
	
	//return @"2f952126";		//@"debug"
}

- (NSString*) appSpec
{
	NSString *specStr;
	if ([networkConfig.pubId2 length] > 0) {
		specStr = networkConfig.pubId2;
	} else if ([adViewDelegate respondsToSelector:@selector(BaiDuApSpecString)]) {
		specStr = [adViewDelegate BaiDuApSpecString];
	} else {
		specStr = @"debug";
	}
    //注意：该计费名为测试用途，不会产生计费，请测试广告展示无误以后，替换为您的应用计费名，然后提交AppStore.
    return specStr;	//@"debug";
}

-(BOOL) enableLocation
{
    //启用location会有一次alert提示
    return [self helperUseGpsMode];
}


-(void) willDisplayAd:(BaiduMobAdView*) adview
{
	/*
	 UIDeviceOrientation co = [UIDevice currentDevice].orientation;
	 if (UIDeviceOrientationIsPortrait(co))
	 {
		 adview.frame = kAdViewPortraitRect;
	 }
	 else
	 {
		 adview.frame = kAdViewLandscapeRect;
	 }	*/
    //视图即将被显示。
	if (!hasGotBaiduAd) hasGotBaiduAd = YES;
	AWLogInfo(@"willDisplay");
#if NEED_IN_REALVIEW
	adview.hidden = NO;
	BaiduMobAdView *view = [adview retain];
//	[adview removeFromSuperview];
#endif
	adview.frame = [AdViewAdapterBaidu adRect];
    [adViewView adapter:self didReceiveAdView:adview];
#if NEED_IN_REALVIEW
	[view release];
#endif
}

-(void) failedDisplayAd:(BaiduMobFailReason) reason;
{
    AWLogInfo(@"fail, reason:%d", reason);
	[adViewView adapter:self didFailAd:nil];
}

@end
