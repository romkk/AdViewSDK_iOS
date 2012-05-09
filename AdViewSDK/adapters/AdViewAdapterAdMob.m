/*

 AdViewAdapterAdmob.m

 Copyright 2009 AdMob, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

#import "AdViewAdapterAdMob.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewViewImpl.h"
#import "GADBannerView.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"

@interface AdViewAdapterAdMob (PRIVATE)

- (NSArray *)testDevices;
- (BOOL)isTestMode;

@end



@implementation AdViewAdapterAdMob

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeAdMob;
}

+ (void)load {
	if(NSClassFromString(@"GADBannerView") != nil && NSClassFromString(@"GADRequest") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class adMobViewClass = NSClassFromString (@"GADBannerView");
	
	if (nil == adMobViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no admob lib, can not create.");
		return;
	}
#if 0
    GADBannerView *adMobView = [adMobViewClass requestAdWithDelegate:self];
#else
    Class GADRequestClass = NSClassFromString(@"GADRequest");
    if (GADRequestClass == nil) {
        [adViewView adapter:self didFailAd:nil];
        AWLogInfo(@"no admob lib, can't create");
        return;
    }
	
	[self updateSizeParameter];

    GADBannerView *adMobView = [[adMobViewClass alloc] initWithFrame:
								CGRectMake(0.0f, 0.0f, self.sSizeAd.width, self.sSizeAd.height)];

    [adMobView performSelector:@selector(setAdUnitID:) withObject:networkConfig.pubId];
    AWLogInfo(@"AdMob ID:%@", adMobView.adUnitID);
    [adMobView performSelector:@selector(setDelegate:) withObject:self];
    [adMobView performSelector:@selector(setRootViewController:) withObject:[adViewDelegate viewControllerForPresentingModalView]];
    //[adMobView loadRequest:[GADRequestClass performSelector: @selector(request)]];
	GADRequest *request = [GADRequestClass request];
	//request.testDevices = [self testDevices];
	request.testing = [self isTestMode];
    [adMobView loadRequest:request];
#endif
    self.adNetworkView = adMobView;
}

- (void)stopBeingDelegate {
  GADBannerView *adMobView = (GADBannerView *)self.adNetworkView;
  if (adMobView != nil) {
      [adMobView performSelector:@selector(setDelegate:) withObject:nil];
      //adMobView.delegate = nil;
      [adMobView performSelector:@selector(setRootViewController:) withObject:nil]; 
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
				self.sSizeAd = CGSizeMake(320, 50);
				break;
			case AdviewBannerSize_300x250:
				self.sSizeAd = CGSizeMake(300, 250);
				break;
			case AdviewBannerSize_480x60:
				self.sSizeAd = CGSizeMake(468, 60);
				break;
			case AdviewBannerSize_728x90:
				self.sSizeAd = CGSizeMake(728, 90);
				break;
		}
	} else if (isIPad) {
		self.sSizeAd = CGSizeMake(728, 90);
	} else {
		self.sSizeAd = CGSizeMake(320, 50);
	}
}

- (void)dealloc {
  [super dealloc];
}

- (BOOL)isTestMode {
	if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)]) {
		return [adViewDelegate adViewTestMode];
	}
	return NO;
}

#pragma mark GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    [adViewView adapter:self didReceiveAdView:view];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    [adViewView adapter:self didFailAd:nil];
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView
{
    //[self helperNotifyDelegateOfFullScreenModal];
    [self helperNotifyDelegateOfFullScreenModal];
}
- (void)adViewDidDismissScreen:(GADBannerView *)adView
{
    [self helperNotifyDelegateOfFullScreenModalDismissal];
}

- (NSArray *)testDevices {
  if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)]
      && [adViewDelegate adViewTestMode]) {
    return [NSArray arrayWithObjects:
            GAD_SIMULATOR_ID,                             // Simulator
            nil];
  }
  return nil;
}

@end
