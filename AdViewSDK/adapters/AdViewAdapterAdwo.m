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
#import "AwAdView.h"
#import "AdViewAdapterAdwo.h"

@interface AdViewAdapterAdwo ()
- (NSString *)adwoPublisherIdForAd;
- (int)mode;
@end


@implementation AdViewAdapterAdwo

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeADWO;
}

+ (void)load {
	if(NSClassFromString(@"AWAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class awAdViewClass = NSClassFromString (@"AWAdView");
	
	if (nil == awAdViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no adwo lib, can not create.");
		return;
	}
	
	[self updateSizeParameter];
    AWAdView* adView = [[awAdViewClass alloc] initWithAdwoPid:[self adwoPublisherIdForAd] adIdType:0 
												   adTestMode: [self mode] 
												 adSizeForPad:self.nSizeAd];

    adView.frame = self.rSizeAd;
    adView.delegate = self;
    
	adView.adRequestTimeIntervel = 30;//时间不要低于30s，以免影响用户体验
	adView.userGpsEnabled = [self helperUseGpsMode];//如果客户应用不支持定位
    
    [adView loadAd];
	
	self.adNetworkView = adView;
    AWLogInfo(@"adview size: %@", NSStringFromCGRect(adView.frame));
}

- (void)stopBeingDelegate {
  AWAdView *adView = (AWAdView *)adNetworkView;
	AWLogInfo(@"--stopBeingDelegate--结束--");
  if (adView != nil) {
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
				self.nSizeAd = ADWO_ADS_BANNER_SIZE_FOR_IPAD_320x50;
				self.rSizeAd = CGRectMake(0, 0, 320, 50);
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = ADWO_ADS_BANNER_SIZE_FOR_IPAD_320x50;
				self.rSizeAd = CGRectMake(0, 0, 320, 50);
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = ADWO_ADS_BANNER_SIZE_FOR_IPAD_320x50;
				self.rSizeAd = CGRectMake(0, 0, 320, 50);
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = ADWO_ADS_BANNER_SIZE_FOR_IPAD_720x110;
				self.rSizeAd = CGRectMake(0, 0, 720, 110);
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = ADWO_ADS_BANNER_SIZE_FOR_IPAD_720x110;
		self.rSizeAd = CGRectMake(0, 0, 720, 110);
	} else {
		self.nSizeAd = ADWO_ADS_BANNER_SIZE_FOR_IPAD_320x50;
		self.rSizeAd = CGRectMake(0, 0, 320, 50);
	}
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark AwAdDelegate methods

- (UIViewController *)viewControllerForPresentingModalView {
  return [adViewDelegate viewControllerForPresentingModalView];
}

- (NSString *)adwoPublisherIdForAd {
	NSString *apID;
	if ([adViewDelegate respondsToSelector:@selector(AdwoApIDString)]) {
		apID = [adViewDelegate AdwoApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	return apID;
	
	//return @"a2c491847b8e4be78b8aa223ae625e43";
}

- (void)adViewDidFailToLoadAd:(AWAdView *)view{
    AWLogInfo(@"adViewDidFailToLoadAd");
    [adViewView adapter:self didFailAd:nil];
}
- (void)adViewDidLoadAd:(AWAdView *)view{
    AWLogInfo(@"adview size: %@", NSStringFromCGRect(view.frame));
    AWLogInfo(@"====adViewDidLoadAd====");
    [adViewView adapter:self didReceiveAdView:view];
}

- (void)willPresentModalViewForAd:(AWAdView *)view{
    AWLogInfo(@"willPresentModalViewForAd");
    [self helperNotifyDelegateOfFullScreenModal];
}
- (void)didDismissModalViewForAd:(AWAdView *)view{
    AWLogInfo(@"didDismissModalViewForAd");
    [self helperNotifyDelegateOfFullScreenModalDismissal];
}

- (int)mode {
	BOOL ret = NO;
	if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)])
		ret = [adViewDelegate adViewTestMode];

	if ( ret == YES )
		return 0;
	else
		return 1;
}

/*

- (UIColor *)domobAdBackgroundColorForAd:(AwAdView *)awAdView {
	return [self helperBackgroundColorToUse];
}

// 设置广告视图中文字的显示颜色
- (UIColor *)domobPrimaryTextColorForAd:(AwAdView *)awAdView {
	return [self helperTextColorToUse];
}
 */
	
@end
