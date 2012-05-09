/*

 adview wooboo.

*/

#import "AdViewAdapterWooboo.h"
#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "CommonADView.h"

@interface AdViewAdapterWooboo (PRIVATE)

//@property (nonatomic, retain) UIView* woobooView;

- (BOOL) testMode;
@end

@interface AdapterImp : NSObject<ADCommonListenerDelegate>
{
	NSMutableArray *arrViews;
	NSObject		*lockObj;
}

@property (nonatomic, assign) AdViewAdapterWooboo *adapter;

@end

@implementation AdapterImp

@synthesize adapter;

-(id)init {
	self = [super init];
	if (nil != self) {
		arrViews = [[NSMutableArray alloc] initWithCapacity:5];
		lockObj = [[NSObject alloc] init];
	}
	return self;
}

- (void)dealloc {
	[arrViews release];
	[lockObj release];
	[super dealloc];
}

-(UIView*)getAdView:(NSString *)apID Test:(BOOL)testMode {
	@synchronized(lockObj) {
	if ([arrViews count] > 0) {
		UIView *view = [[arrViews objectAtIndex:0] retain];
		[arrViews removeObjectAtIndex:0];
		return view;
	} else {
		Class woobooViewClass = NSClassFromString (@"CommonADView");
		if (nil == woobooViewClass) return nil;
		
		CommonADView *commonADView = [[woobooViewClass alloc]
								  initWithPID:apID
								  status: testMode
								  locationX:0 
								  locationY:0
                                  displayType:CommonBannerScreen
                                  screenOrientation:0];

		[commonADView performSelector:@selector(setListenerDelegate:) withObject:self];
		commonADView.requestADTimeIntervel = 20;		//
		[commonADView startADRequest];
		return commonADView;
	}
	}
}

-(void)appendAdView:(UIView *)view {
	@synchronized(lockObj) {
		[arrViews addObject:view];
	}
}

- (void) onFailedToReceiveAD:(NSString *)error
{
	if (nil != self.adapter)
		[self.adapter onFailedToReceiveAD:error];
}

@end


AdapterImp *gAdapterImp = nil;

@implementation AdViewAdapterWooboo
//@synthesize woobooView;

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeWOOBOO;
}

+ (void)load {
	if(NSClassFromString(@"CommonADView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

//sample @"afc507fbcab54cd2b56beacaba74efdc".
- (void)getAd {
  NSString *apID;
  if ([adViewDelegate respondsToSelector:@selector(woobooApIDString)]) {
    apID = [adViewDelegate woobooApIDString];
  }
  else {
    apID = networkConfig.pubId;
  }
	
	Class woobooViewClass = NSClassFromString (@"CommonADView");
	
	if (nil == woobooViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no wooboo lib, can not create.");
		return;
	}
	
	if (nil == gAdapterImp) gAdapterImp = [[AdapterImp alloc] init];
	
	gAdapterImp.adapter = self;
	CommonADView *commonADView = (CommonADView*)[gAdapterImp getAdView:apID Test:[self testMode]];
	
	self.adNetworkView = commonADView;
	/*
	if (nil != commonADView) {
		CGRect frm = commonADView.frame;
		frm.origin.y = 0;
		commonADView.frame = frm;
	}*/
    
	[adViewView adapter:self didReceiveAdView:commonADView];
	[commonADView release];
}

- (void)stopBeingDelegate {
  CommonADView *adView = (CommonADView *)adNetworkView;
	if (adView != nil) {
		gAdapterImp.adapter = nil;
		[gAdapterImp appendAdView:adView];
//		[adView requestADWillStop];
		adNetworkView = nil;
		self.adNetworkView = nil;
  }
  //  self.woobooView = nil;
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


- (BOOL)testMode {
    if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)])
        return [adViewDelegate adViewTestMode];
    return NO;
}

#pragma mark Woooboo methods

- (void) onFailedToReceiveAD:(NSString *)error
{
    [adViewView adapter:self didFailAd:nil];
}

@end
