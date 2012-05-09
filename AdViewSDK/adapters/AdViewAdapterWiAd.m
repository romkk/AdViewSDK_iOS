/*

 adview wooboo.

*/

#import "AdViewAdapterWiAd.h"
#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "WiAdView.h"

@interface AdViewAdapterWiAd ()
-(void) WiAdDidFailLoad:(WiAdView*)adView;
-(NSString *)appId:(WiAdView *)adView;
-(UIColor*) adBackgroundColor;
-(UIColor*) adTextColor;
@end

@implementation AdViewAdapterWiAd

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeWIYUN;
}

+ (void)load {
	if(NSClassFromString(@"WiAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class WiAdViewClass = NSClassFromString (@"WiAdView");
	
	if (nil == WiAdViewClass) {
		[self WiAdDidFailLoad:nil];
		AWLogInfo(@"no WiAd lib, can not create.");
		return;
	}
	
	[self updateSizeParameter];
	//WiAdView* adView = [WiAdViewClass adViewWithResId:[self appId:nil]];//@"填入广告位id"
	WiAdView* adView = [WiAdViewClass adViewWithResId:[self appId:nil] style: self.nSizeAd];

	adView.frame = self.rSizeAd;
	adView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    //设置Delegate对象
    adView.delegate = self;
    //设置广告背景色
    adView.adBgColor = [self adBackgroundColor];
	adView.adTextColor = [self adTextColor];
	
	[adView requestAd];
	
	self.adNetworkView = adView;
}

- (void)stopBeingDelegate {
  WiAdView *adView = (WiAdView *)adNetworkView;
	AWLogInfo(@"--stopBeingDelegate--结束--");
  if (adView != nil) {
	  adView.delegate = nil;
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
				self.nSizeAd = kWiAdViewStyleBanner320_50;
				self.rSizeAd = CGRectMake(0, 0, 320, 50);
				break;
			case AdviewBannerSize_300x250:
				self.nSizeAd = kWiAdViewStyleBanner320_270;
				self.rSizeAd = CGRectMake(0, 0, 320, 270);
				break;
			case AdviewBannerSize_480x60:
				self.nSizeAd = kWiAdViewStyleBanner508_80;
				self.rSizeAd = CGRectMake(0, 0, 508, 80);
				break;
			case AdviewBannerSize_728x90:
				self.nSizeAd = kWiAdViewStyleBanner768_110;
				self.rSizeAd = CGRectMake(0, 0, 768, 110);
				break;
		}
	} else if (isIPad) {
		self.nSizeAd = kWiAdViewStyleBanner768_110;
		self.rSizeAd = CGRectMake(0, 0, 768, 110);
	} else {
		self.nSizeAd = kWiAdViewStyleBanner320_50;
		self.rSizeAd = CGRectMake(0, 0, 320, 50);
	}
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark MMAdDelegate methods

/**
 *	Be sure to return the id you get from WiAd
 */
- (NSString *)appId:(WiAdView *)adView {
	NSString *apID;
	if ([adViewDelegate respondsToSelector:@selector(WiAdApIDString)]) {
		apID = [adViewDelegate WiAdApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	return apID;
}

- (BOOL)WiAdUseTestMode:(WiAdView*)adView{
    //返回是否使用测试模式
	if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)])
		return [adViewDelegate adViewTestMode];
	return NO;
}

- (int)WiAdTestAdType:(WiAdView*)adView{
    //返回测试广告类型
    return TEST_WIAD_TYPE_BANNER;
}

- (void)WiAdDidLoad:(WiAdView*)adView{
    //广告加载成功    
	AWLogInfo(@"loaded WiYun Ad!");
    [adViewView adapter:self didReceiveAdView:adView];
}

- (void)WiAdDidFailLoad:(WiAdView*)adView{
    //广告加载失败
	AWLogInfo(@"WiYun ad fail to load!");
    [adViewView adapter:self didFailAd:nil];
}

-(UIColor*) adBackgroundColor
{
	return [self helperBackgroundColorToUse];
}

-(UIColor*) adTextColor
{
	return [self helperTextColorToUse];
}

//全屏广告关闭按钮点击时调用
- (void)WiAdFullScreenAdSkipped:(WiAdView*)adView {
	AWLogInfo(@"WiYun ad full screen skip!");
}

//全屏广告被点击后调用
- (void)WiAdFullScreenAdClicked:(WiAdView*)adView {
	AWLogInfo(@"WiYun ad full screen clicked!");
}

#pragma mark requestData optional methods

// The follow is kept for gathering requestData

- (BOOL)respondsToSelector:(SEL)selector {
  return [super respondsToSelector:selector];
}

@end
