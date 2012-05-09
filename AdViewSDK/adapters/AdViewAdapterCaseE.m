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
#import "CaseeAdView.h"
#import "AdViewAdapterCaseE.h"

@interface AdViewAdapterCaseeAd ()
- (void)adView:(CaseeAdView *)adView failedWithError:(NSError *)error;
@end


@implementation AdViewAdapterCaseeAd

+ (AdViewAdNetworkType)networkType {
  return AdViewAdNetworkTypeCASEE;
}

+ (void)load {
	if(NSClassFromString(@"CaseeAdView") != nil) {
		[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
	}
}

- (void)getAd {
	Class caseeAdViewClass = NSClassFromString (@"CaseeAdView");
	
	if (nil == caseeAdViewClass) {
		[self adView:nil failedWithError:nil];
		AWLogDebug(@"no adchina lib, can not create.");
		return;
	}
	
	CaseeAdView* adView = [caseeAdViewClass adViewWithDelegate:self doRequest:YES];
	
	self.adNetworkView = adView;
}

- (void)stopBeingDelegate {
  CaseeAdView *adView = (CaseeAdView *)adNetworkView;
	AWLogDebug(@"--stopBeingDelegate--结束--");
  if (adView != nil) {
//	  [adView release];
//	  adNetworkView = nil;
  }
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark MMAdDelegate methods

/**
 * app id assigned in casee.cn. This will be used in an ad request to identify this app.
 */
- (NSString *)appId {
	NSString *apID;
	if ([adViewDelegate respondsToSelector:@selector(caseeApIDString)]) {
		apID = [adViewDelegate caseeApIDString];
	}
	else {
		apID = networkConfig.pubId;
	}
	return apID;
	
	//return @"A20B4DA7124A102A13FBF20E72E6F5F4";
}

- (BOOL)allowShareLocation {
    return NO;
}

// let the SDK get current location.
- (CLLocation *)location {
    return nil;
}

- (NSString *)postalCode {
    return @"";
}

- (NSString *)areaCode {
    return @"";
}

//
// demographics information
// 
- (NSUInteger)age {
    return 0;
}

- (NSDate *)dateOfBirth {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    NSDate *dob = [df dateFromString:@"1722-12-20"];
    [df release];
    return dob;
}

- (NSString *)gender {
    return @"m";
}

- (NSUInteger)income {
    return 100000;
}

// Other information may send with an ad request
- (NSString *)keywords {
    return @"";
}

/**
 * An ad view did recieve an ad. This is called from a background thread.
 * If the adview is not added to this view, do it.
 */
- (void)didReceiveAdIn:(CaseeAdView *)adView {
    AWLogDebug(@"ManualDemo did receive an ad from CASEE");
    [adViewView adapter:self didReceiveAdView:adView];
}

/**
 * An ad view failed to get ad.  This is called from a background thread.
 */
- (void)adView:(CaseeAdView *)adView failedWithError:(NSError *)error {
    AWLogDebug(@"adview failed with error: %@", error);
	[adViewView adapter:self didFailAd:nil];
}

/**
 * Will show landing page.  Normally it's a full screen view or a modal view.
 * It's time to stop animations or other time sensitive interactions.
 */
- (void)willShowFullScreenAd {
    AWLogDebug(@"CaseeAdView will show full screen ad.");
}

/**
 * Close the landing page.  It's time to resume anything you stopped in -willShowLandingPage.
 */
- (void)didCloseFullScreenAd {
    AWLogDebug(@"CaseeAdView did close full screen ad.");
}

//
// test settings
//

/**
 * Specify whether this is in test(development) mode or production mode. Default is NO.
 */ 
- (BOOL)isTestMode {
    return YES;
}

/**
 * Test action type. It can be @"url" or @"itunes".
 */
- (NSString *)testAdAction {
    return @"url";
}

- (NSTimeInterval)adInterval {
    return 40;
}

- (UIColor *)adBackgroundColor {
    return [UIColor purpleColor];
}

- (UIColor *)textColor {
    return [UIColor whiteColor];
}

- (UIColor *)secondaryTextColor {
    return [UIColor orangeColor];
}

#pragma mark requestData optional methods

// The follow is kept for gathering requestData

- (BOOL)respondsToSelector:(SEL)selector {
  return [super respondsToSelector:selector];
}

@end
