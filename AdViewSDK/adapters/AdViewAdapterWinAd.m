#import "AdViewAdapterWinAd.h"
#import "AdViewViewImpl.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewLog.h"
#import "AdViewView.h"

#define WINADBANNERVIEW_CLASS_NAME @"WinView"

@implementation AdViewAdapterWinAd
@synthesize winadIdString = _winadIdString;
@synthesize winadAdView = _winadAdView;

+ (AdViewAdNetworkType) networkType {
    return AdViewAdNetworkTypeWinAd;
}

+ (void) load
{
    if (NSClassFromString(WINADBANNERVIEW_CLASS_NAME)){
        AWLogInfo(@"AdView: Found WinAd AdNetwork");
        [[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
    }
}

- (void) getAd
{
    self.winadIdString = [self.networkConfig pubId];
    AWLogInfo(@"WinAd: application id: %@", self.winadIdString);
    
    UIViewController* controller = [self.adViewDelegate viewControllerForPresentingModalView];

    Class winad_view_class = NSClassFromString(WINADBANNERVIEW_CLASS_NAME);
    UIView* winad_view = [[winad_view_class alloc] initWithController: controller];
    [winad_view performSelector:@selector(setDelegate:) withObject:self];
    CGRect r = CGRectMake(0.0f, 0.0f, 320.0f, 50.0f);
    winad_view.frame = r;
    self.adNetworkView = winad_view;
    self.winadAdView = winad_view;
    [winad_view release];
    [self.winadAdView performSelector:@selector(startRequestAd)];
}

- (void) stopBeingDelegate
{
    UIView* winad_view = self.winadAdView;
    [winad_view performSelector:@selector(setDelegate:) withObject:nil];
    self.winadAdView = nil;
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
    [_winadIdString release];
    [super dealloc];
}

- (NSString*) WinAdDevId: (WinView*) adView
{
    return self.winadIdString;
}

- (NSUInteger) WinAdTestMode : (WinView*) adView
{
    BOOL ret = NO;
	if ([self.adViewDelegate respondsToSelector:@selector(adViewTestMode)])
		ret =  [self.adViewDelegate adViewTestMode];
    
    if (ret == YES) {
        return 0;
    } else {
        return 1;
    }
}

- (void) WinAdDidLoad 
{
    [self.adViewView adapter:self didReceiveAdView:self.winadAdView];
}

- (void) WinAdDidFailLoad
{
    [self.adViewView adapter:self didFailAd:nil];
}
@end
