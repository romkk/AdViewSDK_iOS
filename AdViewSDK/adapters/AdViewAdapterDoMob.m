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
#import "DoMobView.h"
#import "AdViewAdapterDoMob.h"

#define TestUserSpot @"all"

@interface AdViewAdapterDoMob ()
@end


@implementation AdViewAdapterDoMob

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeDOMOB;
}

+ (void)load {
	if(NSClassFromString(@"DoMobView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class doMobViewClass = NSClassFromString (@"DoMobView");
	
	if (nil == doMobViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no domob lib, can not create.");
		return;
	}
	
	[self updateSizeParameter];
	DoMobView* adView = [doMobViewClass requestDoMobViewWithSize:self.sSizeAd WithDelegate:self];
	
	self.adNetworkView = adView;
}

- (void)stopBeingDelegate {
  DoMobView *adView = (DoMobView *)adNetworkView;
	AWLogInfo(@"--stopBeingDelegate--结束--");
  if (adView != nil) {
	  adView.doMobDelegate = nil;
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
				self.sSizeAd = DOMOB_SIZE_320x48;
				break;
			case AdviewBannerSize_300x250:
				self.sSizeAd = DOMOB_SIZE_320x270;
				break;
			case AdviewBannerSize_480x60:
				self.sSizeAd = DOMOB_SIZE_488x80;
				break;
			case AdviewBannerSize_728x90:
				self.sSizeAd = DOMOB_SIZE_748x110;
				break;
		}
	} else if (isIPad) {
		self.sSizeAd = DOMOB_SIZE_748x110;
	} else {
		self.sSizeAd = DOMOB_SIZE_320x48;
	}
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark DoMobDelegate methods
- (UIViewController *)domobCurrentRootViewControllerForAd:(DoMobView *)doMobView
{
  return [adViewDelegate viewControllerForPresentingModalView];
}

- (NSString *)domobPublisherIdForAd:(DoMobView *)doMobView {
	NSString *apID;
	if ([adViewDelegate respondsToSelector:@selector(DoMobApIDString)]) {
		apID = [adViewDelegate DoMobApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	return apID;
	
	//return @"56OJycJIuMWsQqo0JM";
}

- (NSString *)domobSpot:(DoMobView *)doMobView;
{
	return TestUserSpot;
}
// Sent when an ad request loaded an ad; 
// it only send once per DoMobView
- (void)domobDidReceiveAdRequest:(DoMobView *)doMobView
{
    AWLogInfo(@"did receive an ad from domob");
    [adViewView adapter:self didReceiveAdView:doMobView];
}

- (void)domobDidFailToReceiveAdRequest:(DoMobView *)doMobView
{
	AWLogInfo(@"adview failed from domob");
	[adViewView adapter:self didFailAd:nil];
}
/*
 - (UIColor *)adBackgroundColorForAd:(DoMobView *)doMobView
 {
 return [UIColor blackColor];
 }*/

- (void)domobWillPresentFullScreenModalFromAd:(DoMobView *)doMobView
{
	AWLogInfo(@"The view will Full Screen");
	[self helperNotifyDelegateOfFullScreenModal];
}

- (void)domobDidPresentFullScreenModalFromAd:(DoMobView *)doMobView
{
	AWLogInfo(@"The view did Full Screen");
}

- (void)domobWillDismissFullScreenModalFromAd:(DoMobView *)doMobView
{
	AWLogInfo(@"The view will Dismiss Full Screen");
}

- (void)domobDidDismissFullScreenModalFromAd:(DoMobView *)doMobView
{
	AWLogInfo(@"The view did Dismiss Full Screen");
	[self helperNotifyDelegateOfFullScreenModalDismissal];
}

- (BOOL)domobIsTestingMode {
	if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)])
		return [adViewDelegate adViewTestMode];
	return NO;	
}

- (NSInteger)domobRefreshIntervalForAd:(DoMobView *)doMobView {
	return 90;
}

// 设置是否输出调试用的log信息
// 返回值:YES表示输出 NO表示不输出
- (BOOL)domobIsPrintDebugLog {
	return [self domobIsTestingMode];
}

- (UIColor *)domobAdBackgroundColorForAd:(DoMobView *)doMobView {
	return [self helperBackgroundColorToUse];
}

// 设置广告视图中文字的显示颜色
// doMobView:广告视图对象，用于标识哪个对象使用该函数返回值。
// 返回值:表示颜色的UIColor对象，默认值为白色(rgba=FFFFFFFF)。
- (UIColor *)domobPrimaryTextColorForAd:(DoMobView *)doMobView {
	return [self helperTextColorToUse];
}

#if 0	//no data.

- (double)domobLocationLongitude {
	CLLocation *loc = [adViewDelegate locationInfo];
	if (loc == nil) return 0.0;
	return loc.coordinate.longitude;
}

- (double)domobLocationLatitude {
	CLLocation *loc = [adViewDelegate locationInfo];
	if (loc == nil) return 0.0;
	return loc.coordinate.latitude;
}

#endif

// 用于开发者设置是否由SDK自动获取地理位置信息,YES表示获取，NO表示不获取
- (BOOL)domobIsOpenLocation {
	return [self helperUseGpsMode];
}

@end
