#import "AdViewAdapterLmmob.h"
#import "AdViewViewImpl.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewLog.h"
#import "AdViewView.h"
#import "SingletonAdapterBase.h"

@interface AdViewAdapterLmmobImpl : SingletonAdapterBase <LmmobAdBannerViewDelegate> {
}

@end

static AdViewAdapterLmmobImpl *gLmmobImpl = nil;

#define LMMOB_VIEW_CLASS_NAME @"LmmobAdBannerView"
/*
 * Hack for LMMOB
 */

@implementation AdViewAdapterLmmob

+ (AdViewAdNetworkType) networkType {
    return AdViewAdNetworkTypeLmmob;
}

+ (void) load
{
    if (NSClassFromString(LMMOB_VIEW_CLASS_NAME)){
        AWLogInfo(@"AdView: Found LMMob AdNetwork");
        [[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
    }
}

- (void) getAd
{
    Class lmmob_view_class = NSClassFromString(LMMOB_VIEW_CLASS_NAME);
	if (nil == lmmob_view_class) {
		AWLogInfo(@"no lmmob sdk, can not show.");
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	
	if (nil == gLmmobImpl) 
		gLmmobImpl = [[AdViewAdapterLmmobImpl alloc] init];
	
	[gLmmobImpl setAdapter:self];
    LmmobAdBannerView* lmmob_view = (LmmobAdBannerView*)[gLmmobImpl getIdelAdView];
	if (nil == lmmob_view) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	
    self.adNetworkView = lmmob_view;
	[adViewView adapter:self shouldAddAdView:lmmob_view];
	[lmmob_view release];
}

- (void) stopBeingDelegate
{
	AWLogInfo(@"LMMOB stopBeingDelegate");
    LmmobAdBannerView* lmmob_view = (LmmobAdBannerView*)self.adNetworkView;
	[gLmmobImpl setAdapter:nil];
#if 0
    [lmmob_view performSelector:@selector(setDelegate:) withObject:nil];
    [lmmob_view performSelector:@selector(setRootViewController:) withObject:nil];
#else	//reuse lmmob view of the 2.0 sdk, or app will crash if not reuse.
	[gLmmobImpl addIdelAdView:lmmob_view];
#endif
	//[lmmob_view removeFromSuperview];
	//self.adNetworkView = nil;
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

- (void) dealloc
{
    [super dealloc];
}

@end

@implementation AdViewAdapterLmmobImpl

- (void)updateAdFrame:(UIView*)view {
    CGRect r = CGRectMake(0.0f, 0.0f, 320.0f, 50.0f);
    view.frame = r;
}

- (UIView*)createAdView {
    NSString *appIdString = mAdapter.networkConfig.pubId;
    AWLogInfo(@"LMMob: application id: %@", appIdString);
    
    UIViewController* controller = [mAdapter.adViewDelegate viewControllerForPresentingModalView];
    Class lmmob_view_class = NSClassFromString(LMMOB_VIEW_CLASS_NAME);
    LmmobAdBannerView* lmmob_view = [[lmmob_view_class alloc] initWithAdPosition:appIdString withAppVersion:@"1.4.4"];
	
	if (nil == lmmob_view)
		return nil;
	
	AWLogInfo(@"lmmob view:%u", lmmob_view);
	mAdapter.adNetworkView = lmmob_view;
	
	lmmob_view.specId = 1;
	lmmob_view.autoRefreshAdTimeOfSeconds = 30;
    [lmmob_view performSelector:@selector(setDelegate:) withObject:self];
    [lmmob_view performSelector:@selector(setRootViewController:) withObject:controller];
    //if (! global_lmmob_is_actived) {
	[lmmob_view performSelector:@selector(appDidBecomeActiveHandler)];
    //}
    [self updateAdFrame:lmmob_view];
    [lmmob_view requestBannerAd];
	return lmmob_view;
}

- (void) lmmobAdBannerViewDidReceiveAd: (LmmobAdBannerView*) bannerView {
	if (![self isAdViewValid:bannerView]) return;
	
	AWLogInfo(@"Lmmob ad view:%@", bannerView);
	
	[self updateAdFrame:bannerView];
    [mAdapter.adViewView adapter:mAdapter didReceiveAdView:bannerView];	
}

- (void) lmmobAdBannerView: (LmmobAdBannerView*) bannerView didFailReceiveBannerADWithError: (NSError*) error
{
	if (![self isAdViewValid:bannerView]) return;
	
	[mAdapter.adViewView adapter:mAdapter didFailAd:nil];
}

- (void) lmmobAdBannerViewWillPresentScreen: (LmmobAdBannerView*) bannerView
{
    [mAdapter helperNotifyDelegateOfFullScreenModal];
}

- (void) lmmobAdBannerViewDidDismissScreen: (LmmobAdBannerView*) bannerView
{
    [mAdapter helperNotifyDelegateOfFullScreenModalDismissal];
}

- (void) lmmobAdBannerViewDidPresentScreen: (LmmobAdBannerView*) bannerView {
}

- (void) lmmobAdBannerViewWillDismissScreen: (LmmobAdBannerView*) bannerView {
}

- (NSUInteger) lmmobAdBannerViewSetSPECID: (LmmobAdBannerView*) bannerView {
	return 1;
}

@end
