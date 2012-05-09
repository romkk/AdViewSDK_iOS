/*

 AdViewAdapterMillennial.m

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

#import "AdViewAdapterMillennial.h"
#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewDelegateProtocol.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"

#define kMillennialAdFrame_Iphone (CGRectMake(0, 0, 320, 53))
#define kMillennialAdFrame_Ipad (CGRectMake(0, 0, 768, 90))

@interface AdViewAdapterMillennial ()

- (CLLocationDegrees)latitude;

- (CLLocationDegrees)longitude;

- (NSInteger)age;

- (NSString *)zipCode;

- (NSString *)sex;

@end


@implementation AdViewAdapterMillennial

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeMillennial;
}

+ (void)load {
	if(NSClassFromString(@"MMAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
  NSString *apID;
  if ([adViewDelegate respondsToSelector:@selector(millennialMediaApIDString)]) {
    apID = [adViewDelegate millennialMediaApIDString];
  }
  else {
    apID = networkConfig.pubId;
  }

  requestData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                 @"adview", @"vendor",
                 nil];
  if ([self respondsToSelector:@selector(zipCode)]) {
    [requestData setValue:[self zipCode] forKey:@"zip"];
  }
  if ([self respondsToSelector:@selector(age)]) {
    [requestData setValue:[NSString stringWithFormat:@"%d",[self age]] forKey:@"age"];
  }
  if ([self respondsToSelector:@selector(sex)]) {
    [requestData setValue:[self sex] forKey:@"sex"];
  }
  if ([self respondsToSelector:@selector(latitude)]) {
    [requestData setValue:[NSString stringWithFormat:@"%lf",[self latitude]] forKey:@"lat"];
  }
  if ([self respondsToSelector:@selector(longitude)]) {
    [requestData setValue:[NSString stringWithFormat:@"%lf",[self longitude]] forKey:@"long"];
  }
  MMAdType adType = MMBannerAdTop;
	Class mmAdViewClass = NSClassFromString (@"MMAdView");
	
	if (nil == mmAdViewClass) {
		[adViewView adapter:self didFailAd:nil];
		AWLogInfo(@"no Millennial lib, can not create adviewview.");
		return;
	}
	
  [self updateSizeParameter];
  MMAdView *adView = [mmAdViewClass adWithFrame:self.rSizeAd
                                      type:adType
                                      apid:apID
									delegate:self  // Must be set, CANNOT be nil
									loadAd:YES   // Loads an ad immediately
									 startTimer:NO];
	
  adView.rootViewController = [adViewDelegate viewControllerForPresentingModalView];
  self.adNetworkView = adView;
}

- (void)stopBeingDelegate {
  MMAdView *adView = (MMAdView *)adNetworkView;
  if (adView != nil) {
	  adView.refreshTimerEnabled = NO;
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
				self.rSizeAd = kMillennialAdFrame_Iphone;
				break;
			case AdviewBannerSize_300x250:
				self.rSizeAd = kMillennialAdFrame_Iphone;
				break;
			case AdviewBannerSize_480x60:
				self.rSizeAd = kMillennialAdFrame_Iphone;
				break;
			case AdviewBannerSize_728x90:
				self.rSizeAd = kMillennialAdFrame_Ipad;
				break;
		}
	} else if (isIPad) {
		self.rSizeAd = kMillennialAdFrame_Ipad;
	} else {
		self.rSizeAd = kMillennialAdFrame_Iphone;
	}
}

- (void)dealloc {
  [requestData release];
  [super dealloc];
}

#pragma mark MMAdDelegate methods

- (NSDictionary *)requestData {
  AWLogInfo(@"Sending requestData to MM: %@", requestData);
  return requestData;
}

- (BOOL)testMode {
  if ([adViewDelegate respondsToSelector:@selector(adViewTestMode)])
    return [adViewDelegate adViewTestMode];
  return NO;
}

- (void)adRequestSucceeded:(MMAdView *)adView {
  // millennial ads are slightly taller than default frame, at 53 pixels.
  [adViewView adapter:self didReceiveAdView:adNetworkView];
}

- (void)adRequestFailed:(MMAdView *)adView {
  [adViewView adapter:self didFailAd:nil];
}

- (void)adModalWillAppear {
  [self helperNotifyDelegateOfFullScreenModal];
}

- (void)adModalWasDismissed {
  [self helperNotifyDelegateOfFullScreenModalDismissal];
}

#pragma mark requestData optional methods

- (CLLocationDegrees)latitude {
	return 0.0;
}

- (CLLocationDegrees)longitude {
	return 0.0;
}

- (NSInteger)age {
	return -1;
}

- (NSString *)zipCode {
	return @"";
}

- (NSString *)sex {
	return @"";
}

/*
- (NSInteger)householdIncome {
  return (NSInteger)[adViewDelegate incomeLevel];
}

- (MMEducation)educationLevel {
  return [adViewDelegate millennialMediaEducationLevel];
}

- (MMEthnicity)ethnicity {
  return [adViewDelegate millennialMediaEthnicity];
}
*/

@end
