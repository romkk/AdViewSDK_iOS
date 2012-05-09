/*
 
 Adview .
 2012-04-12
 */

#import "AdViewAdapterAirAD.h"
#import "airADView.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewViewImpl.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"

@interface AdViewAdapterAirAD (PIRVATE)

- (NSString *)appId;
- (BOOL)isTestMode;

@end


@implementation AdViewAdapterAirAD

+ (AdViewAdNetworkType)networkType {
	return AdViewAdNetworkTypeAirAD;
}

+ (void)load {
	if(NSClassFromString(@"airADView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class airADViewClass = NSClassFromString (@"airADView");
	
	if (nil == airADViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no airAd lib support, can not create.");
		return;
	}
	
	//设置AppID
	[airADViewClass setAppID:[self appId]];
	//设置是否显示提示信息。方便开发调试。
	[airADViewClass setDebugMode:[self isTestMode]?DEBUG_ON:DEBUG_OFF];
	//设置是否需要取得GPS信息，为得到高质量的广告，建议打开。
	[airADViewClass setGPSMode:[self helperUseGpsMode]?GPS_ON:GPS_OFF];
	
	airADView *airBanner = [[airADViewClass alloc] init];
	[self updateSizeParameter];
	
	CGRect r = CGRectMake(0, 0, AD_SIZE_320x54.width, AD_SIZE_320x54.height);
	
	[airBanner setFrame:r];
	[airBanner setDelegate:self];
	[airBanner setBannerBGMode:BannerBG_ON];
	//设置刷新时必须大于15。单位秒。
	[airBanner setIntervalTime:30];
	//设置刷新模式，自动或者手动。设置为手动，则刷新时间的设置无效,并且需要每次主动调用refreshAd。
	[airBanner setRefreshMode:REFRESH_MODE_MANUAL];

	self.adNetworkView = airBanner;
	[airBanner refreshAd];
	[airBanner release];
    [self setupDummyHackTimer];
}

- (void)stopBeingDelegate {
	airADView *airBanner = (airADView *)self.adNetworkView;
	AWLogInfo(@"airAd stop being delegate");
	if (airBanner != nil) {
		airBanner.delegate = nil;
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
    [self cleanupDummyHackTimer];
    
	[super dealloc];
}

#pragma mark util

- (NSString *)appId {
	NSString *apID;
	if ([adViewDelegate respondsToSelector:@selector(AirADAppIDString)]) {
		apID = [adViewDelegate AirADAppIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
    
	return apID;
	//return @"123456789";
}

- (BOOL)isTestMode {
	if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)]) {
		return [adViewDelegate adViewTestMode];
	}
	return NO;
}

#pragma mark AirADDelegate methods

- (void)airADDidReceiveAD:(airADView*)view {
    [self cleanupDummyHackTimer];
    
	[adViewView adapter:self didReceiveAdView:view];
}

- (void)airADView:(airADView *)view didFailToReceiveAdWithError:(NSError *)error {
	[adViewView adapter:self didFailAd:error];
}

- (void)airADWillShowContent:(airADView *)adView {
	[self helperNotifyDelegateOfFullScreenModal];
}

- (void)airADDidHideContent:(airADView *)adView {
	[self helperNotifyDelegateOfFullScreenModalDismissal];
}

@end
