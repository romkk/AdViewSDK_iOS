/*

 AdViewAdNetworkAdapter.m

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

#import "AdViewAdNetworkAdapter.h"
#import "AdViewViewImpl.h"
#import "AdViewConfig.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkRegistry.h"

BOOL isForeignAd(AdViewAdNetworkType type)
{
	switch (type) {
		case AdViewAdNetworkTypeGreystripe:
		case AdViewAdNetworkTypeAdMob:
		case AdViewAdNetworkTypeIAd:
		case AdViewAdNetworkTypeMillennial:
		case AdViewAdNetworkTypeInMobi:
			return YES;
		default:
			return NO;
	}
	return NO;
}


@implementation AdViewAdNetworkAdapter

@synthesize adViewDelegate;
@synthesize adViewView;
@synthesize adViewConfig;
@synthesize networkConfig;
@synthesize adNetworkView;

@synthesize nSizeAd;
@synthesize rSizeAd;
@synthesize sSizeAd;

@synthesize dummyHackTimer;

- (id)initWithAdViewDelegate:(id<AdViewDelegate>)delegate
                         view:(AdViewView *)view
                       config:(AdViewConfig *)config
                networkConfig:(AdViewAdNetworkConfig *)netConf {
  self = [super init];
  if (self != nil) {
    self.adViewDelegate = delegate;
    self.adViewView = view;
    self.adViewConfig = config;
    self.networkConfig = netConf;
  }
  return self;
}

- (void)getAd {
  AWLogCrit(@"Subclass of AdViewAdNetworkAdapter must implement -getAd.");
  [self doesNotRecognizeSelector:_cmd];
}

- (void)stopBeingDelegate {
  AWLogCrit(@"Subclass of AdViewAdNetworkAdapter must implement -stopBeingDelegate.");
  [self doesNotRecognizeSelector:_cmd];
}

- (BOOL)shouldSendExMetric {
  return YES;
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation {
  // do nothing by default. Subclasses implement specific handling.
  AWLogInfo(@"rotate to orientation %d called for adapter %@",
             orientation, NSStringFromClass([self class]));
}

- (BOOL)isBannerAnimationOK:(AWBannerAnimationType)animType {
  return YES;
}

- (void)updateSizeParameter {
	self.nSizeAd = 0;
	self.rSizeAd = CGRectMake(0, 0, 320.0f, 50.0f);
}

- (void) setupDummyHackTimer
{
    self.dummyHackTimer = [NSTimer scheduledTimerWithTimeInterval: 10 
                                                           target:self 
														 selector:@selector(dummyHackTimerHandler) userInfo:nil 
                                                          repeats:NO];
}

- (void) cleanupDummyHackTimer
{
    [self.dummyHackTimer invalidate];
    self.dummyHackTimer = nil;
}

- (void) dummyHackTimerHandler
{
    self.dummyHackTimer = nil;
    [adViewView adapter:self didFailAd:nil];
}

- (void)dealloc {
  [self stopBeingDelegate];
  adViewDelegate = nil;
  adViewView = nil;
  [adViewConfig release], adViewConfig = nil;
  [networkConfig release], networkConfig = nil;
  [adNetworkView release], adNetworkView = nil;
  [super dealloc];
}

@end
