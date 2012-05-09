/*
 
 Adview .
 2012-04-12
 */

#import "AdViewAdapterWQ.h"
#import "WQAdView.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewViewImpl.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "WQAdSDK.h"
#import "SingletonAdapterBase.h"

#define NEED_IN_REALVIEW 0

@interface AdViewAdapterWQImpl : SingletonAdapterBase <WQAdProtocol> 

- (void)InitSettingXML;

- (NSString *)appId;
- (NSString *)publisherId;

@end

static BOOL		gNeedInitSettingXML = YES;

static AdViewAdapterWQImpl *gWQImpl = nil;

@implementation AdViewAdapterWQ

+ (void)setNeedInitSettingXMLFile {
	gNeedInitSettingXML = YES;
}

+ (AdViewAdNetworkType)networkType {
	return AdViewAdNetworkTypeWQ;
}

+ (void)load {
	if(NSClassFromString(@"WQAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class WQAdViewClass = NSClassFromString (@"WQAdView");
	
	if (nil == WQAdViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no WQMobile lib support, can not create.");
		return;
	}
	
	if (nil == gWQImpl) gWQImpl = [[AdViewAdapterWQImpl alloc] init];
	[gWQImpl setAdapter:self];
	
	WQAdView *wqBanner = (WQAdView*)[gWQImpl getIdelAdView];
	if (nil == wqBanner) {
		[adViewView adapter:self didFailAd:nil];
		return;
	}
	
	self.adNetworkView = wqBanner;
#if NEED_IN_REALVIEW
	if ([adViewDelegate respondsToSelector:@selector(viewControllerForPresentingModalView)])
	{
		UIViewController *controller = [adViewDelegate viewControllerForPresentingModalView];
		if (nil != controller && nil != controller.view)
		{
			[controller.view addSubview:wqBanner];
			wqBanner.frame = CGRectMake(0, 0, 320, 48);
			wqBanner.hidden = YES;
		}
	}
#endif
	[adViewView adapter:self shouldAddAdView:wqBanner];
	[wqBanner startRequestAd];	
	[wqBanner release];
}

- (void)stopBeingDelegate {
	WQAdView *wqBanner = (WQAdView *)self.adNetworkView;
	AWLogInfo(@"WQ stop being delegate");
	if (wqBanner != nil) {
		[gWQImpl addIdelAdView:wqBanner];
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
	[super dealloc];
}

@end

@implementation AdViewAdapterWQImpl


#pragma mark util

- (void)InitSettingXML {
#if 1	//specific sdk will not use AppSettings.xml file.
	Class WQAdSDKClass = NSClassFromString (@"WQAdSDK");
	if (nil == WQAdSDKClass) return;
	[WQAdSDKClass init:[self appId] withPubID:[self publisherId]
  withRefreshRate:30
	   isTestMode:[self isTestMode]];
#else
	NSString *fmtStr = @"<AppSettings>\n"
	"<AppID>%@</AppID>\n"
	"<PublisherID>%@</PublisherID>\n"
	"<URL>http://www.adview.cn/wqmobile</URL>\n"
	"<AppStoreURL><![CDATA[http://itunes.apple.com/jp/app/happybird]]></AppStoreURL>\n" 
	"<UseLocationInfo>N</UseLocationInfo>\n"
	"<RefreshRate>10</RefreshRate>\n" 
	"<TestMode>%@</TestMode>\n"
	"<NextADCount>3</NextADCount>\n" 
	"<LoopTimes>2</LoopTimes>\n"
	"<OfflineADCount>3</OfflineADCount>\n" 
	"<OfflineADSurvivalDays>1</OfflineADSurvivalDays>\n" 
	"<UseEmbeddedBrowser>Y</UseEmbeddedBrowser>\n"
	"<PreferIncome>Y</PreferIncome>\n"			
	"<StretchStrategy>stretch</StretchStrategy>\n"
	"<BackgroundColor>ffffff</BackgroundColor>\n"
	"<TextColor>000000</TextColor>\n"
	"<Width>320</Width>\n"
	"<Height>48</Height>\n" 
	"<TopLeft-x>0</TopLeft-x>\n"
	"<TopLeft-y>0</TopLeft-y>\n"
	"<BackgroundTransparency>0.8</BackgroundTransparency>\n"
	"</AppSettings>";
	
	NSString *testModeStr = [self isTestMode]?@"Y":@"N";
	NSString *settingStr = [[NSString alloc] initWithFormat:fmtStr, [self appId],
							[self publisherId], testModeStr];
	
	//NSBundle *bundle = [NSBundle mainBundle];
	//NSString *dir = [bundle bundlePath];
	NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	AWLogInfo(@"App path:%@", dir);
	
	NSString* xmlPath = [dir stringByAppendingPathComponent:@"AppSettings.xml"];
	
	[settingStr writeToFile:xmlPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[settingStr release];
#endif
}

- (NSString *)appId {
	NSString *apID;
	if ([mAdapter.adViewDelegate respondsToSelector:@selector(WQAppIDString)]) {
		apID = [mAdapter.adViewDelegate WQAppIDString];
	}
	else {
		apID = mAdapter.networkConfig.pubId;
	}
    
	return apID;
	//return @"123456789";
}

- (NSString*)publisherId {
	NSString *idStr;
	if ([mAdapter.adViewDelegate respondsToSelector:@selector(WQPublisherIDString)]) {
		idStr = [mAdapter.adViewDelegate WQPublisherIDString];
	}
	else {
		idStr = mAdapter.networkConfig.pubId2;
	}
    
	return idStr;
}

//PublisherID


- (UIView*)createAdView {
	Class WQAdViewClass = NSClassFromString (@"WQAdView");
	
	if (nil == WQAdViewClass) {
		[mAdapter.adViewView adapter:mAdapter didFailAd:nil];
		AWLogInfo(@"no WQMobile lib support, can not create.");
		return nil;
	}
	
	if (gNeedInitSettingXML) {
		//gNeedInitSettingXML = NO;
		
		[self InitSettingXML];
	}
	[mAdapter updateSizeParameter];
	WQAdView *wqBanner = [[WQAdViewClass requestAdWithDelegate:self] retain];
	return wqBanner;
}


#pragma mark WQDelegate methods

-(void) didReceivedAd:(WQAdView*) adView {
#if NEED_IN_REALVIEW
	[adView setHidden:NO];
#endif
	if (![self isAdViewValid:adView]) return;
		
	CGRect r = CGRectMake(0, 0, WQMOB_SIZE_320x48.width, WQMOB_SIZE_320x48.height);
	[adView setAdRect:r];	
	[mAdapter.adViewView adapter:mAdapter didReceiveAdView:adView];
}

-(void) didFailToReceiveAd:(WQAdView*) adView {
	AWLogInfo(@"WQMobile didFailToReceiveAd");
	if (![self isAdViewValid:adView]) return;
	
	[mAdapter.adViewView adapter:mAdapter didFailAd:nil];
}

-(void) applicationWillPaused:(WQAdView *)adView {
	AWLogInfo(@"wq applicationWillPaused");
	
	//[mAdapter helperNotifyDelegateOfFullScreenModal];
}

-(void) applicationWillTerminated:(WQAdView *)adView {
	AWLogInfo(@"applicationWillTerminated");
}

-(void) applicationResumed:(WQAdView*) adView {
	AWLogInfo(@"wq applicationResumed");
	
	[mAdapter helperNotifyDelegateOfFullScreenModalDismissal];
}

@end
