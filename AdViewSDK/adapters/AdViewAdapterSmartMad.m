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
#import "AdViewAdapterSmartMad.h"

@interface AdViewAdapterSmartMad ()
- (void)didReceiveAd:(UIView *)adView;
- (NSString *)appIdForAd:(UIView *)adView;

- (UIColor *)adBackgroundColor:(UIView *)adView;
- (UIColor *)adTextColor:(UIView *)adView;
@end


@implementation AdViewAdapterSmartMad

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeSMARTMAD;
}

+ (void)load {
	if(NSClassFromString(@"SmartMadAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class smartMadAdViewClass = NSClassFromString (@"SmartMadAdView");
	
	if (nil == smartMadAdViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no smartmad lib, can not create.");
		return;
	}
	
	[smartMadAdViewClass setApplicationId:[self appIdForAd:nil]];
 
	//    [smartMadAdViewClass setUserAge:20];
	//    [smartMadAdViewClass setUserGender:UFemale];
	//    [smartMadAdViewClass setBirthDay:@"20110126"];
	//    [smartMadAdViewClass setFavorite:@"GAME"];
	//    [smartMadAdViewClass setCity:@"shanghia"];
	//    [smartMadAdViewClass setPostalCode:@"200336"];
	//    [smartMadAdViewClass setWork:@"it"];
	//    [smartMadAdViewClass setKeyWord:@"smartmad"];	
	
#if 1
	SmartMadAdView *smartView = [[smartMadAdViewClass alloc] initRequestAdWithDelegate:self];
#else
	SmartMadAdView *smartView = [[smartMadAdViewClass alloc] initRequestAdWithParameters:[self appIdForAd:nil]
														   aInterval:600.0
														   adMeasure:0
												   adBannerAnimation:BANNER_ANIMATION_TYPE_FLIPFROMLEFT 
														 compileMode:AdDebug];
#endif
    [smartView setEventDelegate:self]; // set Ad Event Delegate
	
	self.adNetworkView = smartView;

	[smartView release];
}

- (void)stopBeingDelegate {
  UIView *adView = adNetworkView;
	AWLogInfo(@"--stopBeingDelegate--结束--");
  if (adView != nil) {
	  [adView release];
	  adNetworkView = nil;
	  self.adNetworkView = nil;
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
				self.nSizeAd = PHONE_AD_MEASURE_320X48;
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = TABLET_AD_MEASURE_300X250;
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = TABLET_AD_MEASURE_468X60;
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = TABLET_AD_MEASURE_728X90;
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = TABLET_AD_MEASURE_728X90;
	} else {
		self.nSizeAd = PHONE_AD_MEASURE_320X48;
	}
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark self util methods

- (void)didReceiveAd:(UIView *)adView {
	[adViewView adapter:self didReceiveAdView:adView];
}

- (NSString *)appIdForAd:(UIView *)adView {
	NSString *apID;
	if ([adViewDelegate respondsToSelector:@selector(SmartMadApIDString)]) {
		apID = [adViewDelegate SmartMadApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	return apID;
	
	//return @"03580729f4a07177";
}

- (NSString *)adPositionId {
	if ([adViewDelegate respondsToSelector:@selector(SmartMadBannerAdIDString)]) {
		return [adViewDelegate SmartMadBannerAdIDString];
	}
	else {
		return networkConfig.pubId2;
	}	
	return @"";
	
	//return @"90002436";
}

- (AdCompileMode)compileMode {
	if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)])
		return [adViewDelegate adViewTestMode]?AdDebug:AdRelease;
	return AdRelease;	
}


-(NSTimeInterval)adInterval {
	return 600.;
}

-(AdBannerTransitionAnimationType)adBannerAnimation {
	return BANNER_ANIMATION_TYPE_RANDOM;
}

-(AdMeasureType)adMeasure {
	[self updateSizeParameter];
	return self.nSizeAd;
}

- (UIColor *)adBackgroundColor:(UIView *)adView {
	return [self helperBackgroundColorToUse];
}

- (UIColor *)adTextColor:(UIView *)adView {
	return [self helperTextColorToUse];
}

#pragma mark SmartMad delegate methods

- (void)adEvent:(SmartMadAdView*)adview  adEventCode:(AdEventCodeType)eventCode
{
	CGRect frm = adview.frame;
	BOOL isIPad = [AdViewAdNetworkAdapter helperIsIpad];
	frm.size = isIPad?CGSizeMake(728, 90):CGSizeMake(320, 48);	//should set the size.
	adview.frame = frm;
	if (EVENT_NEWAD == eventCode) {
		[self didReceiveAd:adview];
	} else if (EVENT_INVALIDAD == eventCode) {
		[adViewView adapter:self didFailAd:nil];
	}
}

// callback current ad fullscreen status
- (void)adFullScreenStatus:(BOOL)isFullScreen
{
    if (isFullScreen) [self helperNotifyDelegateOfFullScreenModal];
	else [self helperNotifyDelegateOfFullScreenModalDismissal];
}

#pragma mark requestData optional methods

// The follow is kept for gathering requestData

- (BOOL)respondsToSelector:(SEL)selector {
  return [super respondsToSelector:selector];
}

@end
