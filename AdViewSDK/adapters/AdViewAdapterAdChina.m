/*

 adview wooboo.

*/

#import "AdViewAdapterAdChina.h"
#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdChinaBannerView.h"

#define KADCHINA_DETAULT_FRAME (CGRectMake(0,0,KADVIEW_WIDTH,64))
#define KADCHINA_LANDSCAPE_FRAME (CGRectMake(0,0,KLANDSCAPE_WIDTH,45))

#define ADCHINA_FRAME_AUTO		0

@interface AdViewAdapterAdChinaImpl : NSObject <AdChinaBannerViewDelegate> {
	AdViewAdapterAdChina	*mAdapter;
	NSMutableArray			*mIdelViewArr;
}

@property (nonatomic, assign) AdViewAdapterAdChina	*mAdapter;
@property (nonatomic, retain) NSMutableArray		*mIdelViewArr;

- (void)setAdapter:(AdViewAdapterAdChina*)adapter;
- (AdChinaBannerView*)getIdelAdChinaView:(UIViewController*)controller;
- (void)addIdelAdChinaView:(AdChinaBannerView*)view;
- (NSString *)adSpaceId:(AdChinaBannerView *)adView;

@end

static AdViewAdapterAdChinaImpl *gAdChinaImpl = nil;

@implementation AdViewAdapterAdChina

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeADCHINA;
}

+ (void)load {
	if(NSClassFromString(@"AdChinaBannerView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	if (nil == gAdChinaImpl) 
		gAdChinaImpl = [[AdViewAdapterAdChinaImpl alloc] init];
	mDelegate = gAdChinaImpl;
	[mDelegate setAdapter:self];
	
	AdChinaBannerView *adView = [mDelegate getIdelAdChinaView:[adViewDelegate viewControllerForPresentingModalView]];
	
	if (nil == adView) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	[adView setAnimationMask:AnimationMaskNone];
	[adView setRefreshInterval:20];
	
#if ADCHINA_FRAME_AUTO
	UIDeviceOrientation orientation;
	if ([self.adViewDelegate respondsToSelector:@selector(adViewCurrentOrientation)]) {
		orientation = [self.adViewDelegate adViewCurrentOrientation];
	}
	else {
		orientation = [UIDevice currentDevice].orientation;
	}
	
	if (UIDeviceOrientationIsLandscape(orientation)) {
		[adView setAdFrame:KADCHINA_LANDSCAPE_FRAME];
	} else {
		[adView setAdFrame:KADCHINA_DETAULT_FRAME];
	}
#else
    CGRect r = adView.frame;
    r.origin = CGPointMake(0, 0);
	[self updateSizeParameter];
	r.size = self.sSizeAd;
    adView.frame = r;
//    adView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin
//	| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
#endif
	
	self.adNetworkView = adView;
}

- (void)stopBeingDelegate {
  AdChinaBannerView *adView = (AdChinaBannerView *)adNetworkView;
	AWLogInfo(@"--stopBeingDelegate--结束--");
  if (adView != nil) {
#if 1
	  [mDelegate addIdelAdChinaView:adView];
#else
	  self.adNetworkView = nil;	//to test if can adchina view be alloced and released. fail.
#endif
	  [mDelegate setAdapter:nil];
	  
	  adNetworkView = nil;
  }
	mDelegate = nil;
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
				self.sSizeAd = CGSizeMake(320, 48);
				break;
			case AdviewBannerSize_300x250:
				self.sSizeAd = CGSizeMake(320, 48);
				break;
			case AdviewBannerSize_480x60:
				self.sSizeAd = CGSizeMake(728, 90);
				break;
			case AdviewBannerSize_728x90:
				self.sSizeAd = CGSizeMake(728, 90);
				break;
		}
	} else if (isIPad) {
		self.sSizeAd = BannerSize;
	} else {
		self.sSizeAd = BannerSize;
	}
}

#if ADCHINA_FRAME_AUTO
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation {
	AdChinaView *adView = (AdChinaView *)self.adNetworkView;
	if (adView == nil) return;
	if (UIDeviceOrientationIsLandscape(orientation)) {
		[adView setAdFrame:KADCHINA_LANDSCAPE_FRAME];
	} else {
		[adView setAdFrame:KADCHINA_DETAULT_FRAME];
	}
}
#endif

- (void)dealloc {
  [super dealloc];
}

@end

@implementation AdViewAdapterAdChinaImpl
@synthesize mAdapter;
@synthesize mIdelViewArr;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return NO;
}

- (BOOL) isAdViewValid:(AdChinaBannerView*)adView {
	if (nil == mAdapter || nil == mAdapter.adNetworkView || mAdapter.adNetworkView != (UIView*)adView) {
		AWLogInfo(@"--AdChina stale delegate call--------");	
		return NO;
	}
	return YES;
}

- (void)setAdapter:(AdViewAdapterAdChina*)adapter {
	mAdapter = adapter;
}

- (AdChinaBannerView*)getIdelAdChinaView:(UIViewController *)controller {
	AdChinaBannerView	*ret;
	
	if (nil == mIdelViewArr) 
		mIdelViewArr = [[NSMutableArray alloc] initWithCapacity:10];
	
	if ([mIdelViewArr count] > 0) {
		ret = [mIdelViewArr objectAtIndex:[mIdelViewArr count]-1];
		[mIdelViewArr removeLastObject];
	}
	else {
		Class adChinaViewClass = NSClassFromString (@"AdChinaBannerView");
		
		if (0 == adChinaViewClass) {
			AWLogInfo(@"no adchina lib, can not create.");
			return 0;
		}
		
		ret = [adChinaViewClass requestAdWithAdSpaceId:[self adSpaceId:nil] delegate:self];
		[ret setViewController:controller];
	}
	return ret;
}

- (void)addIdelAdChinaView:(AdChinaBannerView*)view {
	for (int i = 0; i < [mIdelViewArr count]; i++) {
		if (view == [mIdelViewArr objectAtIndex:i])
			return;
	}
	
	[mIdelViewArr addObject:view];
}

- (void)dealloc {
	[mIdelViewArr release];
	[super dealloc];
}

#pragma mark AdChinaDelegate methods
- (void) didGetBannerAd: (AdChinaBannerView *) adView {
	AWLogInfo(@"AdChina: Did receive ad");
	AdViewAdapterAdChina *adapter = mAdapter;
	CGRect r = adView.frame;
	AWLogInfo(@"%f,%f,%f,%f", r.origin.x, r.origin.y, r.size.width, r.size.height);
	
	if (![self isAdViewValid:adView]) return;
	
	[adapter.adViewView adapter:adapter didReceiveAdView:adView];
}

- (void) didFailedToGetBannerAd: (AdChinaBannerView*) adView {
	AWLogInfo(@"AdChina: Failed to receive ad");
	AdViewAdapterAdChina *adapter = mAdapter;
	
	if (![self isAdViewValid:adView]) return;
	
	[adapter.adViewView adapter:adapter didFailAd:nil];
}


#pragma mark MMAdDelegate methods

/**
 *	Be sure to return the id you get from AdChina
 */
- (NSString *)adSpaceId:(AdChinaBannerView *)adView {
	NSString *apID;
	AdViewAdapterAdChina *adapter = mAdapter;
	
	if (nil == adapter) return @""; 
	
	if ([adapter.adViewDelegate respondsToSelector:@selector(adChinaApIDString)]) {
		apID = [adapter.adViewDelegate adChinaApIDString];
	}
	else {
		apID = adapter.networkConfig.pubId;
	}
	return apID;
	
	//return @"69329";
}

- (void)didGetBanner:(AdChinaBannerView *)adView {
	AWLogInfo(@"AdChina: Did receive ad");
	AdViewAdapterAdChina *adapter = mAdapter;
	
	if (![self isAdViewValid:adView]) return;
	
	[adapter.adViewView adapter:adapter didReceiveAdView:adView];
}

- (void)didFailToGetBanner:(AdChinaBannerView *)adView
{
	AWLogInfo(@"AdChina: Failed to receive ad");
	AdViewAdapterAdChina *adapter = mAdapter;
	
	if (![self isAdViewValid:adView]) return;
	
	[adapter.adViewView adapter:adapter didFailAd:nil];
}

- (void)didEnterFullScreenMode
{
	AdViewAdapterAdChina *adapter = mAdapter;
	
	[adapter helperNotifyDelegateOfFullScreenModal];
	AWLogInfo(@"AdChina: Did click on an ad");
}

- (void)didExitFullScreenMode
{
	AdViewAdapterAdChina *adapter = mAdapter;
	
	[adapter helperNotifyDelegateOfFullScreenModalDismissal];
	AWLogInfo(@"AdChina: Did back from ad web");
}

- (NSString *)phoneNumber
{
	return @"";		// return user's phone number if possible
}

- (Sex)gender
{
	return SexUnknown;		// return user's gender if possible
}

- (NSString *)postalCode
{
	return @"";		// return user's postcode if possible
}

- (NSString *)dateOfBirth
{
	return @"";		// return user's birthday if possible
}

#pragma mark requestData optional methods

// The follow is kept for gathering requestData

- (BOOL)respondsToSelector:(SEL)selector {
  return [super respondsToSelector:selector];
}

- (UIViewController*) viewControllerForBannerAd:(AdChinaBannerView *)adView
{
    return [mAdapter.adViewDelegate viewControllerForPresentingModalView];
}
@end
