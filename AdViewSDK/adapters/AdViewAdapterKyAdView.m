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
#import "AdViewAdapterKyAdView.h"
#import "AdOnPlatform.h"

@interface AdViewAdapterKyAdView ()
- (BOOL)isTestMode;
@end


@implementation AdViewAdapterKyAdView

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeAdviewApp;
}

+ (void)load {
	if(NSClassFromString(@"KAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];	
	}
}

- (void)getAd {
	Class KyAdViewAdOnClass = NSClassFromString (@"KAdView");
	
	if (nil == KyAdViewAdOnClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no KyAdView lib, can not create.");
		return;
	}
	
	[self updateSizeParameter];
	
	KAdView *adView = [KyAdViewAdOnClass requestOfSize: self.sSizeAd withDelegate:self];
	
	//[adViewView adapter:self shouldAddAdView:adView];
	self.adNetworkView = adView;
	[adView resumeRequestAd];
}

- (void)stopBeingDelegate {
  KAdView *adView = (KAdView *)self.adNetworkView;
	AWLogInfo(@"--stopBeingDelegate--结束--");
  if (adView != nil) {
	  [adView pauseRequestAd];
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
				self.sSizeAd = KADVIEW_SIZE_320x44;
				break;
			case AdviewBannerSize_300x250:
				self.sSizeAd = KADVIEW_SIZE_320x270;
				break;
			case AdviewBannerSize_480x60:
				self.sSizeAd = KADVIEW_SIZE_480x80;
				break;
			case AdviewBannerSize_728x90:
				self.sSizeAd = KADVIEW_SIZE_760x110;
				break;
		}
	} else if (isIPad) {
		self.sSizeAd = KADVIEW_SIZE_760x110;
	} else {
		self.sSizeAd = KADVIEW_SIZE_320x44;
	}
}

- (void)dealloc {
  [super dealloc];
}

- (BOOL)isTestMode {
	if (nil != adViewDelegate
		&& [adViewDelegate respondsToSelector:@selector(adViewTestMode)]) {
		return [adViewDelegate adViewTestMode];
	}
	return NO;
}

- (NSString *) appId {
	NSString *apID;

	apID = [adViewDelegate adViewApplicationKey];

	return apID;
}

- (NSString*) kAdViewHost {
	return self.networkConfig.pubId2;
}

-(int)	autoRefreshInterval {
	return -1;
}

-(BOOL) testMode {
	return [self isTestMode];
}

#pragma mark Delegate

-(UIColor*) adTextColor {
	return [self helperTextColorToUse];
}

-(UIColor*) adBackgroundColor {
	return [self helperBackgroundColorToUse];
}

-(void) didReceivedAd: (KAdView*) adView {
	AWLogInfo(@"did receive an ad from KyAdView");
    [adViewView adapter:self didReceiveAdView:adView];	
}

-(void) didFailToReceiveAd: (KAdView*) adView {
	AWLogInfo(@"adview failed from KyAdView");
	[adViewView adapter:self didFailAd:nil];		
}

@end
