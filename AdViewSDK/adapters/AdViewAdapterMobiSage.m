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
#import "AdViewAdapterMobiSage.h"

#define TestUserSpot @"all"

@interface NotificationReceiver : NSObject
{
	NSTimer *delayNotifyTimer;
}

@property (retain) NSTimer *delayNotifyTimer;
@property (retain) AdViewAdapterMobiSage *adatper;

@end

@implementation NotificationReceiver

@synthesize adatper;

@synthesize delayNotifyTimer;

- (id)init {
	self = [super init];
	if (nil != self) {
	}
	return self;
}

- (void)dealloc {
	if (nil != delayNotifyTimer) {
		[delayNotifyTimer invalidate];
		delayNotifyTimer = nil;
	}
	
	[super dealloc];
}

- (void) mobiSageCallback: (UIView*) view
{
	AWLogInfo(@"mobiSageCallback, won't do.");
}

- (void) delayMobiSageStartShowAd: (UIView*) view {
	AWLogInfo(@"delayMobiSageStartShowAd");
	if (nil != self.delayNotifyTimer) {
		[self.delayNotifyTimer invalidate];
		self.delayNotifyTimer = nil;
	}
	if (nil == self.adatper) return;
	
	self.delayNotifyTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self	
											 selector:@selector(mobiSageStartShowAd:)
											 userInfo:view
											  repeats:NO];
}

- (void) mobiSageStartShowAd: (UIView*) view
{
	if (nil != self.adatper) {
		[self.adatper performSelector:@selector(mobiSageStartShowAd:) withObject:view];
	}
}

- (void) mobiSageStopShowAd: (UIView*) view
{
	self.delayNotifyTimer = nil;
	if (nil != self.adatper) {
		[self.adatper performSelector:@selector(mobiSageStopShowAd:) withObject:view];
	}
}

- (void) mobiSageWillPopAd: (UIView*) view
{
	if (nil != self.adatper) {
		[self.adatper performSelector:@selector(mobiSageWillPopAd:) withObject:view];
	}
}

- (void) mobiSageHidePopAd: (UIView*) view
{
	if (nil != self.adatper) {
		[self.adatper performSelector:@selector(mobiSageHidePopAd:) withObject:view];
	}
}

@end

NotificationReceiver *gReceiver = nil;


@implementation AdViewAdapterMobiSage
@synthesize adViewInternal;
@synthesize mobiSageAdView;

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeAdSage;
}

+ (void)load {
	if(NSClassFromString(@"MobiSageManager") != nil) {
        AWLogInfo(@"AdView: Find MobiSage AdNetork");
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
    NSString *apID = @"";

	Class mobiSageAdBannerClass = NSClassFromString (@"MobiSageAdBanner");
	if (nil == mobiSageAdBannerClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no mobisage lib, can not create.");
		return;
	}

	if ([adViewDelegate respondsToSelector:@selector(mobiSageApIDString)]) {
		apID = [adViewDelegate mobiSageApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	
	[self updateSizeParameter];
	
#if 0	//根据厂商建议，不调用此。
    Class mobiSageAdViewManagerClass = NSClassFromString (@"MobiSageManager");
	if (nil != mobiSageAdViewManagerClass) 
		[[mobiSageAdViewManagerClass getInstance] setPublisherID:apID];
#endif
	
	UIView* dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.sSizeAd.width, self.sSizeAd.height)];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    MobiSageAdBanner* adView = [[mobiSageAdBannerClass alloc] initWithAdSize:self.nSizeAd PublisherID:apID];
	
	if (nil == adView) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
#if 1
	if (nil == gReceiver) gReceiver = [[NotificationReceiver alloc] init];
	if (nil != gReceiver) {
		gReceiver.adatper = self;
		
		[nc addObserver:gReceiver selector:@selector(mobiSageStartShowAd:) name:MobiSageAdView_Start_Show_AD object:adView];
		[nc addObserver:gReceiver selector:@selector(mobiSageStopShowAd:) name:MobiSageAdView_Pause_Show_AD object:adView];
		[nc addObserver:gReceiver selector:@selector(mobiSageCallback:) name:MobiSageAdView_Refresh_AD object:adView];
		[nc addObserver:gReceiver selector:@selector(mobiSageWillPopAd:) name:MobiSageAdView_Pop_AD_Window object:nil];
		[nc addObserver:gReceiver selector:@selector(mobiSageHidePopAd:) name:MobiSageAdView_Hide_AD_Window object:nil];
	}
#else
    [nc addObserver:self selector:@selector(mobiSageStartShowAd:) name:MobiSageAdView_Start_Show_AD object:adView];
    [nc addObserver:self selector:@selector(mobiSageStopShowAd:) name:MobiSageAdView_Pause_Show_AD object:adView];
	[nc addObserver:self selector:@selector(mobiSageRefreshAd:) name:MobiSageAdView_Refresh_AD object:self.mobiSageAdView];
    [nc addObserver:self selector:@selector(mobiSageWillPopAd:) name:MobiSageAdView_Pop_AD_Window object:nil];
    [nc addObserver:self selector:@selector(mobiSageHidePopAd:) name:MobiSageAdView_Hide_AD_Window object:nil];
#endif
	adView.frame = CGRectMake(0, 0, self.sSizeAd.width,self.sSizeAd.height);
	[adView setSwitchAnimeType:Random];
	[adView	setInterval:Ad_NO_Refresh];
    dummyView.backgroundColor = [UIColor clearColor];
    //[dummyView addSubview:adView];
    self.adNetworkView = dummyView;
	self.adViewInternal = dummyView;
    [self.adViewInternal addSubview:adView];
    self.mobiSageAdView = adView;
    [adView release];
    //[self.adViewView adapter:self shouldAddAdView:self.adViewInternal];
    [dummyView release];
    [self setupDummyHackTimer];
}

- (void)stopBeingDelegate {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
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
				self.nSizeAd = Ad_320X40;
				self.sSizeAd = CGSizeMake(320, 40);
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = Ad_320X270;
				self.sSizeAd = CGSizeMake(320, 270);
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = Ad_480X40;
				self.sSizeAd = CGSizeMake(480, 40);
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = Ad_748X60;
				self.sSizeAd = CGSizeMake(748, 60);
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = Ad_748X60;
		self.sSizeAd = CGSizeMake(748, 60);
	} else {
		self.nSizeAd = Ad_320X40;
		self.sSizeAd = CGSizeMake(320, 40);
	}
}

- (void) mobiSageStartShowAd: (UIView*) view
{
	AWLogInfo(@"mobiSageStartShowAd");
    [self cleanupDummyHackTimer];
    
    [self.adViewInternal addSubview:self.mobiSageAdView];
	[self.adViewView adapter:self didReceiveAdView:self.adViewInternal];
}

- (void) mobiSageStopShowAd: (UIView*) view
{
    AWLogInfo(@"mobiSageStartStopAd");
}

- (void) mobiSageWillPopAd: (UIView*) view
{
	AWLogInfo(@"mobiSageWillPopAd");
    //[self helperNotifyDelegateOfFullScreenModal];
}

- (void) mobiSageRefreshAd: (UIView*) view
{
	AWLogInfo(@"mobiSageRefreshAd");
}

- (void) mobiSageHidePopAd: (UIView*) view
{
	AWLogInfo(@"mobiSageHidePopAd");
    //[self helperNotifyDelegateOfFullScreenModalDismissal];
}

- (void)dealloc {
	AWLogInfo(@"adapter mobisage dealloc");
	
    [self.mobiSageAdView removeFromSuperview];
	self.mobiSageAdView = nil;
	
    [self cleanupDummyHackTimer];
	
	[self.adViewInternal removeFromSuperview];
    self.adViewInternal = nil;
	
	[super dealloc];
}

@end
