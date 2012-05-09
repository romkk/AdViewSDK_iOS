#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewAdapterAdFracta.h"

#define ADFRACTA_VIEW_CLASS_NAME @"AdFractaView"

@implementation AdViewAdapterAdFracta
@synthesize adfractaIdString = _adfractaIdString;
@synthesize adfractaAdView = _adfractaAdView;

+ (AdViewAdNetworkType) networkType {
    return AdViewAdNetworkTypeAdFracta;
}

+ (void) load
{
    if (NSClassFromString(ADFRACTA_VIEW_CLASS_NAME)){
        AWLogInfo(@"AdView: Found WinAd AdNetwork");
        [[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
    }
}

- (void) getAd
{
    self.adfractaIdString = self.networkConfig.pubId;
    AWLogInfo(@"AdFracta: application id: %@", self.adfractaIdString);
    
    UIViewController* controller = [self.adViewDelegate viewControllerForPresentingModalView];

    Class adfracta_view_class = NSClassFromString(ADFRACTA_VIEW_CLASS_NAME);
	
	
	[self updateSizeParameter];
    CGRect r = CGRectMake(0.0f, 0.0f, self.sSizeAd.width, self.sSizeAd.height);
    UIView* adfracta_view = [adfracta_view_class photoAdWithFrame:r delegate:self adType: MCAD_TOP];
    [adfracta_view performSelector:@selector(setRootViewController_:) withObject: controller];
    adfracta_view.frame = r;
    self.adNetworkView = adfracta_view;
    self.adfractaAdView = adfracta_view;
    [self.adfractaAdView performSelector:@selector(startRequest)];
}

- (void) stopBeingDelegate
{
    //UIView* adfracta_view = self.adfractaAdView;
    //[adfracta_view performSelector:@selector(setDelegate:) withObject:nil];
    self.adfractaAdView = nil;
}

- (void)updateSizeParameter {
	BOOL isIPad = [AdViewAdNetworkAdapter helperIsIpad];
	
	AdviewBannerSize	sizeId = AdviewBannerSize_Auto;
	if ([self.adViewDelegate respondsToSelector:@selector(PreferBannerSize)]) {
		sizeId = [self.adViewDelegate PreferBannerSize];
	}
	
	if (sizeId > AdviewBannerSize_Auto) {
		switch (sizeId) {
			case AdviewBannerSize_320x50:
				self.nSizeAd = 0;
				self.sSizeAd = AD_SIZE_320x48;
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = 0;
				self.sSizeAd = AD_SIZE_320x270;
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = 0;
				self.sSizeAd = AD_SIZE_488x80;
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = 0;
				self.sSizeAd = AD_SIZE_748x110;
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = 0;
		self.sSizeAd = AD_SIZE_748x110;
	} else {
		self.nSizeAd = 0;
		self.sSizeAd = AD_SIZE_320x48;
	}
}

- (void) dealloc
{
    [_adfractaIdString release];
    [super dealloc];
}

- (NSString*) publisherid
{
    return self.adfractaIdString;
}

- (BOOL) shouldCloseAdFractaView: (AdFractaView*) adView
{
    return NO;
}

- (void) didReceiveAd: (AdFractaView*) adView
{
    [self.adViewView adapter:self didReceiveAdView:self.adfractaAdView];
}

- (void) didFailToReceiveAd: (AdFractaView*) adView
{
    [self.adViewView adapter:self didFailAd:nil];
}
@end
