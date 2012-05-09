/*

 AdViewView.m

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

#import "AdViewViewImpl.h"
#import "AdViewView+.h"
#import "AdViewConfigStore.h"
#import "AdViewAdNetworkConfig.h"
#import "CJSONDeserializer.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter.h"
#import "AdViewError.h"
#import "AdViewConfigStore.h"
#import "AWNetworkReachabilityWrapper.h"

#import "AdViewAdapterAdMob.h"
#import "AdViewAdapterMillennial.h"
#import "AdViewAdapterDoMob.h"
#import "AdViewAdapterWooboo.h"
#import "AdViewAdapterYouMi.h"
#import "AdViewAdapterIAd.h"
#import "AdViewAdapterWiAd.h"
#import "AdViewAdapterAdChina.h"
#import "AdViewAdapterSmartMad.h"
#import "AdViewAdapterVpon.h"
#import "AdViewAdapterAdwo.h"
#import "AdViewAdapterIZP.h"
#import "AdViewDeviceCollector.h"
#define kAdViewViewAdSubViewTag   1000


NSInteger adNetworkPriorityComparer(id a, id b, void *ctx) {
  AdViewAdNetworkConfig *acfg = a, *bcfg = b;
  if(acfg.priority < bcfg.priority)
    return NSOrderedAscending;
  else if(acfg.priority > bcfg.priority)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

@implementation AdViewView

@synthesize delegate;
@synthesize lastError;
@synthesize testDarts;

- (void)startGetConfig {
}

+ (AdViewView *)requestAdViewViewWithDelegate:(id<AdViewDelegate>)delegate {
	if (![delegate respondsToSelector:
		  @selector(viewControllerForPresentingModalView)]) {
		[NSException raise:@"AdViewIncompleteDelegateException"
					format:@"AdViewDelegate must implement"
		 @" viewControllerForPresentingModalView"];
	}
	
	//in static lib, should regester etc.
#if 0
    /* Not need load , runtime will load automaticlly */
	[AdViewAdapterAdMob load];
	[AdViewAdapterMillennial load];
	[AdViewAdapterWooboo load];
	[AdViewAdapterYouMi load];
	[AdViewAdapterIAd load];
	[AdViewAdapterWiAd load];
	[AdViewAdapterAdChina load];
	[AdViewAdapterDoMob load];
	[AdViewAdapterSmartMad load];
	[AdViewAdapterVpon load];
	[AdViewAdapterAdwo load];
	[AdViewAdapterIZP load];
	[AdViewAdapterBaidu load];
#endif
	bool testMode = NO;
	if ([delegate respondsToSelector:@selector(adViewTestMode)])
		testMode = [delegate adViewTestMode];
	
	if (testMode) {
		if (DEBUG_INFO) AWLogSetLogLevel(AWLogLevelDebug);
		else AWLogSetLogLevel(AWLogLevelInfo);
	} else AWLogSetLogLevel(AWLogLevelNone);
	
	AdViewView *adView
    = [[[AdViewViewImpl alloc] initWithDelegate:delegate] autorelease];
	[adView startGetConfig];  // errors are communicated via delegate
	return adView;
}

static id<AdViewDelegate> classAdViewDelegateForConfig = nil;

+ (void)startPreFetchingConfigurationDataWithDelegate:
(id<AdViewDelegate>)delegate {
	if (classAdViewDelegateForConfig != nil) {
		AWLogWarn(@"Called startPreFetchingConfig when another fetch is"
				  @" in progress");
		return;
	}
	classAdViewDelegateForConfig = delegate;
	[[AdViewConfigStore sharedStore] getConfig:[delegate adViewApplicationKey]
									  delegate:(id<AdViewConfigDelegate>)self];
}

+ (void)updateAdViewConfigWithDelegate:(id<AdViewDelegate>)delegate {
	if (classAdViewDelegateForConfig != nil) {
		AWLogWarn(@"Called updateConfig when another fetch is in progress");
		return;
	}
	classAdViewDelegateForConfig = delegate;
	[[AdViewConfigStore sharedStore]
	 fetchConfig:[delegate adViewApplicationKey]
	 blockMode:YES
	 delegate:(id<AdViewConfigDelegate>)self];
}

// next methods only provide empty operation, all acture should be taken in AdViewViewImpl

- (void)updateAdViewConfig{}

- (void)requestFreshAd{}

- (void)rollOver {}

- (BOOL)adExists {
	return true;
}

- (CGSize)actualAdSize {
	return CGSizeMake(50, 50);
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation {
}

- (NSString *)mostRecentNetworkName {
	return nil;
}

- (void)replaceBannerViewWith:(UIView*)bannerView {
}

- (void)adapter:(AdViewAdNetworkAdapter *)adapter shouldAddAdView:(UIView *)view {}

- (void)adapter:(AdViewAdNetworkAdapter *)adapter
didReceiveAdView:(UIView *)view {}
- (void)adapter:(AdViewAdNetworkAdapter *)adapter didFailAd:(NSError *)error {}
- (void)adapterDidFinishAdRequest:(AdViewAdNetworkAdapter *)adapter{}

- (void)stopAutoRefresh{}
- (void)startAutoRefresh{}
- (BOOL)isAutoRefreshStarted {
	return false;
}

- (void)setInShowingModalView:(BOOL)bModal{}

@end


@implementation AdViewViewImpl

#pragma mark Properties getters/setters

@synthesize config;
@synthesize config_noblocking;
@synthesize prioritizedAdNetCfgs;
@synthesize currAdapter;
@synthesize lastAdapter;
@synthesize lastRequestTime;
@synthesize refreshTimer;
@synthesize configTimer;
@synthesize configStore;
@synthesize rollOverReachability;

- (void)setDelegate:(id <AdViewDelegate>)theDelegate {
  [self willChangeValueForKey:@"delegate"];
  delegate = theDelegate;
  if (self.currAdapter) {
    self.currAdapter.adViewDelegate = theDelegate;
  }
  if (self.lastAdapter) {
    self.lastAdapter.adViewDelegate = theDelegate;
  }
  [self didChangeValueForKey:@"delegate"];
}


#pragma mark Life cycle methods

- (id)initWithDelegate:(id<AdViewDelegate>)d {
  self = [super initWithFrame:KADVIEW_DETAULT_FRAME];
  if (self != nil) {
    delegate = d;
    self.backgroundColor = [UIColor clearColor];
    // to prevent ugly artifacts if ad network banners are bigger than the
    // default frame
    self.clipsToBounds = YES;
    showingModalView = NO;
    appInactive = NO;

    // default config store. Can be overridden for testing
    self.configStore = [AdViewConfigStore sharedStore];

    // get notified of app activity
    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
    [notifCenter addObserver:self
                    selector:@selector(resignActive:)
                        name:UIApplicationWillResignActiveNotification
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(becomeActive:)
                        name:UIApplicationDidBecomeActiveNotification
                      object:nil];
      AdViewDeviceCollector* deviceCollector = [AdViewDeviceCollector sharedDeviceCollector];
      deviceCollector.delegate = self;
      [deviceCollector postDeviceInformation];
    // remember pending ad requests, so we don't make more than one
    // request per ad network at a time
    pendingAdapters = [[NSMutableDictionary alloc] initWithCapacity:30];
  }
  return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	delegate = nil;
	
	[config removeDelegate:self];
	[config release], config = nil;
	
	[config_noblocking removeDelegate:self];
	[config_noblocking release], config_noblocking = nil; 	
	
  [prioritizedAdNetCfgs release], prioritizedAdNetCfgs = nil;	
  totalPercent = 0.0;
  requesting = NO;
  currAdapter.adViewDelegate = nil, currAdapter.adViewView = nil;
  [currAdapter release], currAdapter = nil;
  lastAdapter.adViewDelegate = nil, lastAdapter.adViewView = nil;
  [lastAdapter release], lastAdapter = nil;
  [lastRequestTime release], lastRequestTime = nil;
  [pendingAdapters release], pendingAdapters = nil;
  if (refreshTimer != nil) {
    [refreshTimer invalidate];
    refreshTimer = nil;
  }
	if (nil != configTimer) {
		[configTimer invalidate];
		configTimer = nil;
	}
  [lastError release], lastError = nil;

  [super dealloc];
}


#pragma mark Config and setup methods

- (void)startGetConfig {
  // Invalidate ad refresh timer as it may change with the new config
  if (self.refreshTimer) {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
  }
	if (self.configTimer) {
		[self.configTimer invalidate];
		self.configTimer = nil;
	}
	
  configFetchAttempts = 0;
  AdViewConfig *cfg = [configStore getConfig:[delegate adViewApplicationKey]
                                     delegate:(id<AdViewConfigDelegate>)self];
	cfg.langSet = LangSetType_None;
	if (nil != delegate && [delegate respondsToSelector:@selector(PreferLangSet)]) {
		cfg.langSet = [delegate PreferLangSet];
	}
  self.config = cfg;
}

- (void)attemptFetchConfig:(NSNumber*)blocking {
  AdViewConfig *cfg = [configStore fetchConfig:[delegate adViewApplicationKey]
									 blockMode:[blocking boolValue]
									  delegate:(id<AdViewConfigDelegate>)self];
  if (cfg != nil) {
	  if ([blocking boolValue])
		  self.config = cfg;
	  else self.config_noblocking = cfg;
  }
}

- (void)attemptFetchFileConfig:(NSNumber*)blocking {
	AdViewConfig *cfg = [configStore fetchFileConfig:[delegate adViewApplicationKey]
										   blockMode:[blocking boolValue]
											  method:ConfigMethod_DataFile
											delegate:(id<AdViewConfigDelegate>)self];
	if (cfg != nil) {
		if (blocking)
			self.config = cfg;
		else self.config_noblocking = cfg;
	}
}

- (void)attemptFetchOfflineConfig:(NSNumber*)blocking {
	AdViewConfig *cfg = [configStore fetchFileConfig:[delegate adViewApplicationKey]
										   blockMode:[blocking boolValue]
											  method:ConfigMethod_OfflineFile
											delegate:(id<AdViewConfigDelegate>)self];
	if (cfg != nil) {
		if ([blocking boolValue])
			self.config = cfg;
		else self.config_noblocking = cfg;
	}
}

- (void)updateAdViewConfig {
  // Invalidate ad refresh timer as it may change with the new config
/*  if (self.refreshTimer) {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
  }
*/
  // Request new config
  AWLogInfo(@"======== Updating config ========");
  configFetchAttempts = 0;
  //[self attemptFetchConfig:[NSNumber numberWithBool:NO]];
    [self performSelectorOnMainThread:@selector(attemptFetchConfig:)
                           withObject:[NSNumber numberWithBool:NO]
                        waitUntilDone:YES];	
}

#pragma mark Ads management private methods

- (void)buildPrioritizedAdNetCfgsAndMakeRequest {
  NSMutableArray *freshNetCfgs = [[NSMutableArray alloc] init];
  for (AdViewAdNetworkConfig *cfg in config.adNetworkConfigs) {
    // do not add the ad network in rotation if there's already a stray
    // pending ad request to this ad network (due to network outage or plain
    // slow request)
    NSNumber *netKey = [NSNumber numberWithInt:(int)cfg.networkType];
    if ([pendingAdapters objectForKey:netKey] == nil) {
      [freshNetCfgs addObject:cfg];
    }
    else {
      AWLogInfo(@"Already has pending ad request for network type %d,"
                 @" not adding ad network config %@",
                 cfg.networkType, cfg);
    }
  }
  [freshNetCfgs sortUsingFunction:adNetworkPriorityComparer context:nil];
  totalPercent = 0.0;
  for (AdViewAdNetworkConfig *cfg in freshNetCfgs) {
    totalPercent += cfg.trafficPercentage;
  }
  self.prioritizedAdNetCfgs = freshNetCfgs;
  [freshNetCfgs release];

  [self makeAdRequest:YES];
}

static BOOL randSeeded = NO;
- (double)nextDart {
  if (testDarts != nil) {
    if (testDartIndex >= [testDarts count]) {
      testDartIndex = 0;
    }
    NSNumber *nextDartNum = [testDarts objectAtIndex:testDartIndex];
    double dart = [nextDartNum doubleValue];
    if (dart >= totalPercent) {
      dart = totalPercent - 0.001;
    }
    testDartIndex++;
    return dart;
  }
  else {
    if (!randSeeded) {
      srandom(CFAbsoluteTimeGetCurrent());
      randSeeded = YES;
    }
    return ((double)(random()-1)/RAND_MAX) * totalPercent;
  }
}

- (AdViewAdNetworkConfig *)nextNetworkCfgByPercent {
  if ([prioritizedAdNetCfgs count] == 0) {
    return nil;
  }

  double dart = [self nextDart];

  double tempTotal = 0.0;

  AdViewAdNetworkConfig *result = nil;
  for (AdViewAdNetworkConfig *network in prioritizedAdNetCfgs) {
    result = network; // make sure there is always a network chosen
    tempTotal += network.trafficPercentage;
    if (dart < tempTotal) {
      // this is the one to use.
      break;
    }
  }

  AWLogInfo(@">>>> By Percent chosen %@ (%@), dart %lf in %lf",
        result.nid, result.networkName, dart, totalPercent);
  return result;
}

- (AdViewAdNetworkConfig *)nextNetworkCfgByPriority {
  if ([prioritizedAdNetCfgs count] == 0) {
    return nil;
  }
  AdViewAdNetworkConfig *result = [prioritizedAdNetCfgs objectAtIndex:0];
  AWLogInfo(@">>>> By Priority chosen %@ (%@)",
             result.nid, result.networkName);
  return result;
}

- (void)makeAdRequest:(BOOL)isFirstRequest {
  if ([prioritizedAdNetCfgs count] == 0) {
    // ran out of ad networks
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestNoMoreAdNetworks
                            description:@"No more ad networks to roll over"];
    return;
  }

  if (showingModalView) {
    AWLogInfo(@"Modal view is active, not going to request another ad");
    return;
  }

  self.rollOverReachability = nil;  // stop any roll over reachability checks

  if (requesting) {
    // it is OK to request a new one while another one is in progress
    // the adapter callbacks from the old adapter will be ignored.
    // User-initiated request ad will be blocked in requestFreshAd.
    AWLogInfo(@"Already requesting ad, will request a new one.");
  }
  requesting = YES;

  AdViewAdNetworkConfig *nextAdNetCfg = nil;

  if (isFirstRequest && totalPercent > 0.0) {
    nextAdNetCfg = [self nextNetworkCfgByPercent];
  }
  else {
    nextAdNetCfg = [self nextNetworkCfgByPriority];
  }
  if (nextAdNetCfg == nil) {
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestNoMoreAdNetworks
                            description:@"No more ad networks to request"];
    return;
  }

  AdViewAdNetworkAdapter *adapter =
    [[nextAdNetCfg.adapterClass alloc] initWithAdViewDelegate:delegate
                                                           view:self
                                                         config:config
                                                  networkConfig:nextAdNetCfg];
  // keep the last adapter around to catch stale ad network delegate calls
  // during transitions
  self.lastAdapter = self.currAdapter;
  self.currAdapter = adapter;
  [adapter release];

  // take nextAdNetCfg out so we don't request again when we roll over
  [prioritizedAdNetCfgs removeObject:nextAdNetCfg];

  if (lastRequestTime) {
    [lastRequestTime release];
  }
  lastRequestTime = [[NSDate date] retain];

  // remember this pending request so we do not request again when we make
  // new ad requests
  NSNumber *netTypeKey = [NSNumber numberWithInt:(int)nextAdNetCfg.networkType];
  [pendingAdapters setObject:currAdapter forKey:netTypeKey];

  // If last adapter is of the same network type, make the last adapter stop
  // being an ad network view delegate to prevent the last adapter from calling
  // back to this AdViewView during the transition and afterwards.
  // We should not do this for all adapters, because if the last adapter is
  // still in progress, we need to know about it in the adapter callbacks.
  // That the last adapter is the same type as the new adapter is possible only
  // if the last ad request finished, i.e. called back to its adapters. There
  // are cases, e.g. iAd, when the ad network may call back multiple times,
  // because of internal refreshes.
  if (self.lastAdapter.networkConfig.networkType ==
                                  self.currAdapter.networkConfig.networkType) {
    [self.lastAdapter stopBeingDelegate];
  }

	if ([delegate respondsToSelector:@selector(adViewStartGetAd:)]) {
		[delegate adViewStartGetAd:self];
	}	
  [currAdapter getAd];
}

- (void)setInShowingModalView:(BOOL)bModal {
	showingModalView = bModal;
}

- (BOOL)canRefresh {
  return !(ignoreNewAdRequests
           || ignoreAutoRefreshTimer
           || appInactive
           || showingModalView);
}

- (void)timerRequestFreshAd {
  if (![self canRefresh]) {
    AWLogInfo(@"Not going to refresh due to flags, app not active or modal");
    return;
  }
  if (lastRequestTime != nil) {
    NSTimeInterval sinceLast = -[lastRequestTime timeIntervalSinceNow];
    if (sinceLast <= kAWMinimumTimeBetweenFreshAdRequests) {
      AWLogInfo(@"Ad refresh timer fired too soon after last ad request,"
                 @" ignoring");
      return;
    }
  }
  AWLogInfo(@"======== Refreshing ad due to timer ========");
  [self buildPrioritizedAdNetCfgsAndMakeRequest];
}

#pragma mark Ads management public methods

- (void)requestFreshAd {
  // only make request in main thread
  if (![NSThread isMainThread]) {
    [self performSelectorOnMainThread:@selector(requestFreshAd)
                           withObject:nil
                        waitUntilDone:NO];
    return;
  }
  if (ignoreNewAdRequests) {
    // don't request new ad
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestIgnoredError
                            description:@"ignoreNewAdRequests flag set"];
    return;
  }
  if (requesting) {
    // don't request if there's a request outstanding
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestInProgressError
                            description:@"Ad request already in progress"];
    return;
  }
  if (showingModalView) {
    // don't request if there's a modal view active
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestModalActiveError
                            description:@"Modal view active"];
    return;
  }
  if (!config) {
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestNoConfigError
                            description:@"No ad configuration"];
    return;
  }
  if (lastRequestTime != nil) {
    NSTimeInterval sinceLast = -[lastRequestTime timeIntervalSinceNow];
    if (sinceLast <= kAWMinimumTimeBetweenFreshAdRequests) {
      NSString *desc
        = [NSString stringWithFormat:
           @"Requesting fresh ad too soon! It has been only %lfs. Minimum %lfs",
           sinceLast, kAWMinimumTimeBetweenFreshAdRequests];
      [self notifyDelegateOfErrorWithCode:AdViewAdRequestTooSoonError
                              description:desc];
      return;
    }
  }
  [self buildPrioritizedAdNetCfgsAndMakeRequest];
}

- (void)rollOver {
  if (ignoreNewAdRequests) {
    return;
  }
  // only make request in main thread
  if (![NSThread isMainThread]) {
    [self performSelectorOnMainThread:@selector(rollOver)
                           withObject:nil
                        waitUntilDone:NO];
    return;
  }
  [self makeAdRequest:NO];
}

- (BOOL)adExists {
  UIView *currAdView = [self viewWithTag:kAdViewViewAdSubViewTag];
  return currAdView != nil;
}

- (NSString *)mostRecentNetworkName {
  if (currAdapter == nil) return nil;
  return currAdapter.networkConfig.networkName;
}

- (void)stopAutoRefresh {
  ignoreAutoRefreshTimer = YES;
}

- (void)startAutoRefresh {
  ignoreAutoRefreshTimer = NO;
}

- (BOOL)isAutoRefreshStarted {
  return ignoreAutoRefreshTimer;
}

- (void)ignoreNewAdRequests {
  ignoreNewAdRequests = YES;
}

- (void)doNotIgnoreNewAdRequests {
  ignoreNewAdRequests = NO;
}

- (BOOL)isIgnoringNewAdRequests {
  return ignoreNewAdRequests;
}


#pragma mark Stats reporting methods

- (void)metricPing:(NSURL *)endPointBaseURL
               nid:(NSString *)nid
           netType:(AdViewAdNetworkType)type {
  // use config.appKey not from [delegate adViewApplicationKey] as delegate
  // can be niled out at this point. Attempt at Issue #42 .
	UIDevice *myDevice = [UIDevice currentDevice];
	NSString *deviceID = [myDevice uniqueIdentifier];
	
  NSString *query
    = [NSString stringWithFormat:
       @"?appid=%@&nid=%@&type=%d&uuid=%@&country_code=%@&appver=%d&client=1",
       config.appKey,
       nid,
       type,
	   deviceID,
       [[NSLocale currentLocale] localeIdentifier],
       KADVIEW_APP_VERSION];
  NSURL *metURL = [NSURL URLWithString:query
                         relativeToURL:endPointBaseURL];
  AWLogInfo(@"Sending metric ping to %@", metURL);
  NSURLRequest *metRequest = [NSURLRequest requestWithURL:metURL];
  [NSURLConnection connectionWithRequest:metRequest
                                delegate:nil]; // fire and forget
}

- (void)reportExImpression:(NSString *)nid netType:(AdViewAdNetworkType)type {
  NSURL *baseURL = nil;
#if ALL_ORG_DELEGATE_METHODS			//2010.12.24, laizhiwen	
  if ([delegate respondsToSelector:@selector(adViewImpMetricURL)]) {
    baseURL = [delegate adViewImpMetricURL];
  }
#endif
  if (baseURL == nil) {
    baseURL = [NSURL URLWithString:[self adViewImpMetricBaseURLString]];
  }
  [self metricPing:baseURL nid:nid netType:type];
}

- (void)reportExClick:(NSString *)nid netType:(AdViewAdNetworkType)type {
  NSURL *baseURL = nil;
#if ALL_ORG_DELEGATE_METHODS			//2010.12.24, laizhiwen	
  if ([delegate respondsToSelector:@selector(adViewClickMetricURL)]) {
    baseURL = [delegate adViewClickMetricURL];
  }
#endif
  if (baseURL == nil) {
    baseURL = [NSURL URLWithString:[self adViewClickMetricBaseURLString]];
  }
  [self metricPing:baseURL nid:nid netType:type];
}


#pragma mark UI methods

- (CGSize)actualAdSize {
  if (currAdapter == nil || currAdapter.adNetworkView == nil)
	  return KADVIEW_ZERO_SIZE;//KADVIEW_DETAULT_SIZE;
  return currAdapter.adNetworkView.frame.size;
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation {
  if (currAdapter == nil) return;
  [currAdapter rotateToOrientation:orientation];
}

- (void)transitionToView:(UIView *)view {
  UIView *currAdView = [self viewWithTag:kAdViewViewAdSubViewTag];
  if (view == currAdView) {
#if 1
    AWLogInfo(@"ignoring ad transition to itself");
    return; // no need to transition to itself
#else
	  //let it transition.
#endif
  }
  view.tag = kAdViewViewAdSubViewTag;
  if (currAdView) {
    // swap
    currAdView.tag = 0;

    AWBannerAnimationType animType;
    if (config.bannerAnimationType == AWBannerAnimationTypeRandom) {
      if (!randSeeded) {
        srandom(CFAbsoluteTimeGetCurrent());
      }
      // range is 1 to 7, inclusive
      animType = (random() % 7) + 1;
      AWLogInfo(@"Animation type chosen by random is %d", animType);
    }
    else {
      animType = config.bannerAnimationType;
    }
    if (![currAdapter isBannerAnimationOK:animType]) {
      animType = AWBannerAnimationTypeNone;
    }

    if (animType == AWBannerAnimationTypeNone) {
      [currAdView removeFromSuperview];
      [self addSubview:view];
      if ([delegate respondsToSelector:
                                    @selector(adViewDidAnimateToNewAdIn:)]) {
        // no animation, callback right away
        [(NSObject *)delegate
              performSelectorOnMainThread:@selector(adViewDidAnimateToNewAdIn:)
                               withObject:self
                            waitUntilDone:NO];
      }
    }
    else {
      switch (animType) {
        case AWBannerAnimationTypeSlideFromLeft:
        {
          CGRect f = view.frame;
          f.origin.x = -f.size.width;
          view.frame = f;
          [self addSubview:view];
          break;
        }
        case AWBannerAnimationTypeSlideFromRight:
        {
          CGRect f = view.frame;
          f.origin.x = self.frame.size.width;
          view.frame = f;
          [self addSubview:view];
          break;
        }
        case AWBannerAnimationTypeFadeIn:
          view.alpha = 0;
          [self addSubview:view];
          break;
        default:
          // no setup required for other animation types
          break;
      }

      [currAdView retain]; // will be released when animation is done
      AWLogInfo(@"Beginning AdViewAdTransition animation"
                 @" currAdView %x incoming %x", currAdView, view);
      [UIView beginAnimations:@"AdViewAdTransition" context:currAdView];
      [UIView setAnimationDelegate:self];
      [UIView setAnimationDidStopSelector:
            @selector(newAdAnimationDidStopWithAnimationID:finished:context:)];
      [UIView setAnimationBeginsFromCurrentState:YES];
      [UIView setAnimationDuration:1.0];
      // cache has to set to NO because of VideoEgg
      switch (animType) {
        case AWBannerAnimationTypeFlipFromLeft:
          [self addSubview:view];
          [currAdView removeFromSuperview];
          [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                                 forView:self
                                   cache:NO];
          break;
        case AWBannerAnimationTypeFlipFromRight:
          [self addSubview:view];
          [currAdView removeFromSuperview];
          [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
                                 forView:self
                                   cache:NO];
          break;
        case AWBannerAnimationTypeCurlUp:
          [self addSubview:view];
          [currAdView removeFromSuperview];
          [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp
                                 forView:self
                                   cache:NO];
          break;
        case AWBannerAnimationTypeCurlDown:
          [self addSubview:view];
          [currAdView removeFromSuperview];
          [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown
                                 forView:self
                                   cache:NO];
          break;
        case AWBannerAnimationTypeSlideFromLeft:
        case AWBannerAnimationTypeSlideFromRight:
        {
          CGRect f = view.frame;
          f.origin.x = 0;
          view.frame = f;
          break;
        }
        case AWBannerAnimationTypeFadeIn:
          view.alpha = 1.0;
          break;
        default:
          [self addSubview:view];
          AWLogWarn(@"Unrecognized Animation type: %d", animType);
          break;
      }
      [UIView commitAnimations];
    }
  }
  else {  // currAdView
    // new
    [self addSubview:view];
    if ([delegate respondsToSelector:@selector(adViewDidAnimateToNewAdIn:)]) {
      // no animation, callback right away
      [(NSObject *)delegate
              performSelectorOnMainThread:@selector(adViewDidAnimateToNewAdIn:)
                               withObject:self
                            waitUntilDone:NO];
    }
  }
}

- (void)replaceBannerViewWith:(UIView*)bannerView {
  [self transitionToView:bannerView];
}

// Called at the end of the new ad animation; we use this opportunity to do
// memory management cleanup. See the comment in adDidLoad:.
- (void)newAdAnimationDidStopWithAnimationID:(NSString *)animationID
                                    finished:(BOOL)finished
                                     context:(void *)context
{
  AWLogInfo(@"animation %@ finished %@ context %x",
             animationID, finished? @"YES":@"NO", context);
  UIView *adViewToRemove = (UIView *)context;
  [adViewToRemove removeFromSuperview];
  [adViewToRemove release]; // was retained before beginAnimations
  lastAdapter.adViewDelegate = nil, lastAdapter.adViewView = nil;
  self.lastAdapter = nil;
  if ([delegate respondsToSelector:@selector(adViewDidAnimateToNewAdIn:)]) {
    [delegate adViewDidAnimateToNewAdIn:self];
  }
}


#pragma mark UIView touch methods

- (BOOL)_isEventATouch30:(UIEvent *)event {
  if ([event respondsToSelector:@selector(type)]) {
    return event.type == UIEventTypeTouches;
  }
  return YES; // UIEvent in 2.2.1 has no type property, so assume yes.
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  BOOL itsInside = [super pointInside:point withEvent:event];
  if (itsInside && currAdapter != nil && lastNotifyAdapter != currAdapter
      && [self _isEventATouch30:event]
      && [currAdapter shouldSendExMetric]) {
    lastNotifyAdapter = currAdapter;
    [self reportExClick:currAdapter.networkConfig.nid
                netType:currAdapter.networkConfig.networkType];
  }
  return itsInside;
}


#pragma mark UIView methods

- (void)willMoveToSuperview:(UIView *)newSuperview {
  if (newSuperview == nil) {
    [refreshTimer invalidate];
    self.refreshTimer = nil;
	  [configTimer invalidate];
	  self.configTimer = nil;
  }
}


#pragma mark Adapter callbacks

// Chores that are common to all adapter callbacks
- (void)adRequestReturnsForAdapter:(AdViewAdNetworkAdapter *)adapter {
  // no longer pending. Need to retain and autorelease the adapter
  // since the adapter may not be retained anywhere else other than the pending
  // dict
  NSNumber *netTypeKey
    = [NSNumber numberWithInt:(int)adapter.networkConfig.networkType];
  AdViewAdNetworkAdapter *pendingAdapter
    = [pendingAdapters objectForKey:netTypeKey];
  if (pendingAdapter != nil) {
    if (pendingAdapter != adapter) {
      // Possible if the ad refreshes itself and sends callbacks doing so, while
      // a new ad of the same network is pending (e.g. iAd)
      AWLogError(@"Stored pending adapter %@ for network type %@ is different"
                 @" from the one sending the adapter callback %@",
                 pendingAdapter,
                 netTypeKey,
                 adapter);
    }
    [[pendingAdapter retain] autorelease];
    [pendingAdapters removeObjectForKey:netTypeKey];
  }
}

- (void)adapter:(AdViewAdNetworkAdapter *)adapter
          didReceiveAdView:(UIView *)view {
  [self adRequestReturnsForAdapter:adapter];
  if (adapter != currAdapter) {
    AWLogInfo(@"Received didReceiveAdView from a stale adapter %@", adapter);
    return;
  }
  AWLogInfo(@"Received ad from adapter (nid %@)", adapter.networkConfig.nid);

  // UIView operations should be performed on main thread
#if 1
  [self performSelectorOnMainThread:@selector(transitionToView:)
                         withObject:view
                      waitUntilDone:NO];
#else
    [self performSelector:@selector(transitionToView:) withObject:view];
#endif
  requesting = NO;

  // report impression and notify delegate
  if ([adapter shouldSendExMetric]) {
    [self reportExImpression:adapter.networkConfig.nid
                     netType:adapter.networkConfig.networkType];
  }
  if ([delegate respondsToSelector:@selector(adViewDidReceiveAd:)]) {
    [delegate adViewDidReceiveAd:self];
  }
}

- (void)adapter:(AdViewAdNetworkAdapter *)adapter shouldAddAdView:(UIView *)view {
	[self adRequestReturnsForAdapter:adapter];
	if (adapter != currAdapter) {
		AWLogInfo(@"Received didReceiveAdView from a stale adapter %@", adapter);
		return;
	}
	AWLogInfo(@"Received ad from adapter (nid %@)", adapter.networkConfig.nid);
	
	// UIView operations should be performed on main thread
#if 1
	[self performSelectorOnMainThread:@selector(transitionToView:)
						   withObject:view
						waitUntilDone:NO];
#else
    [self performSelector:@selector(transitionToView:) withObject:view];
#endif

	if ([delegate respondsToSelector:@selector(adViewDidReceiveAd:)]) {
		[delegate adViewDidReceiveAd:self];
	}
}

- (void)adapter:(AdViewAdNetworkAdapter *)adapter didFailAd:(NSError *)error {
  [self adRequestReturnsForAdapter:adapter];
  if (adapter != currAdapter) {
    AWLogInfo(@"Received didFailAd from a stale adapter %@: %@",
               adapter, error);
    return;
  }
  AWLogInfo(@"Failed to receive ad from adapter (nid %@): %@",
             adapter.networkConfig.nid, error);
  requesting = NO;

  if ([prioritizedAdNetCfgs count] == 0) {
    // we have run out of networks to try and need to error out.
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestNoMoreAdNetworks
                            description:@"No more ad networks to roll over"];
    return;
  }

#if FAIL_TO_ROLLOVER		//laizhiwen 110415
  // try to roll over, but before we do, check to see if the failure is because
  // network has gotten unreachable. If so, don't roll over. Use www.google.com
  // as test, assuming www.google.com itself is always up if there's network.
  self.rollOverReachability
    = [AWNetworkReachabilityWrapper reachabilityWithHostname:@"www.google.com"
                                            callbackDelegate:self];
  if (self.rollOverReachability == nil) {
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestNoNetworkError
                            description:@"Failed network reachability test"];
    return;
  }
  if (![self.rollOverReachability scheduleInCurrentRunLoop]) {
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestNoNetworkError
                            description:@"Failed network reachability test"];
    return;
  }
#endif
}

- (void)adapterDidFinishAdRequest:(AdViewAdNetworkAdapter *)adapter {
  [self adRequestReturnsForAdapter:adapter];
  if (adapter != currAdapter) {
    AWLogInfo(@"Received adapterDidFinishAdRequest from a stale adapter");
    return;
  }
  // view is supplied via other mechanism (e.g. Generic Notification or Event)
  requesting = NO;

  // report impression. No need to notify delegate because delegate is notified
  // via Generic Notification or event.
  if ([adapter shouldSendExMetric]) {
    [self reportExImpression:adapter.networkConfig.nid
                     netType:adapter.networkConfig.networkType];
  }
}


#pragma mark AWNetworkReachabilityDelegate methods

- (void)reachabilityNotReachable:(AWNetworkReachabilityWrapper *)reach {
  if (reach == self.rollOverReachability) {
    self.rollOverReachability = nil;  // release it and unschedule
    [self notifyDelegateOfErrorWithCode:AdViewAdRequestNoNetworkError
                            description:@"No network connection for rollover"];
    return;
  }
  AWLogWarn(@"Unrecognized reachability called not reachable %s:%d",
            __FILE__, __LINE__);
}

- (void)reachabilityBecameReachable:(AWNetworkReachabilityWrapper *)reach {
  if (reach == self.rollOverReachability) {
    // not an error, just need to rollover
    [lastError release], lastError = nil;
    if ([delegate respondsToSelector:
         @selector(adViewDidFailToReceiveAd:usingBackup:)]) {
      [delegate adViewDidFailToReceiveAd:self usingBackup:YES];
    }
    self.rollOverReachability = nil;   // release it and unschedule
    [self rollOver];
    return;
  }
  AWLogWarn(@"Unrecognized reachability called reachable %s:%d",
            __FILE__, __LINE__);
}


#pragma mark AdViewConfigDelegate methods

+ (NSURL *)adViewConfigURL {
#if ALL_ORG_DELEGATE_METHODS			//2010.12.24, laizhiwen
  if (classAdViewDelegateForConfig != nil
      && [classAdViewDelegateForConfig respondsToSelector:
                                        @selector(adViewConfigURL)]) {
    return [classAdViewDelegateForConfig adViewConfigURL];
  }
#else
	return [NSURL URLWithString:kAdViewDefaultConfigURL];
#endif
  return nil;
}

+ (void)adViewConfigDidReceiveConfig:(AdViewConfig *)config {
  AWLogInfo(@"Fetched Ad network config: %@", config);
  if (classAdViewDelegateForConfig != nil
      && [classAdViewDelegateForConfig respondsToSelector:
                                        @selector(adViewDidReceiveConfig:)]) {
    [classAdViewDelegateForConfig adViewDidReceiveConfig:nil];
  }
  classAdViewDelegateForConfig = nil;
}

+ (void)adViewConfigDidFail:(AdViewConfig *)cfg error:(NSError *)error {
  AWLogError(@"Failed pre-fetching AdView config: %@", error);
  classAdViewDelegateForConfig = nil;
}

- (void)adViewConfigDidReceiveConfig:(AdViewConfig *)cfg {
	if (nil != cfg && !cfg.fetchBlockMode) {
		if (cfg != self.config_noblocking) {
			AWLogWarn(@"background AdViewView: getting adViewConfigDidReceiveConfig callback"
					  @" from unknown AdViewConfig object");			
			return;
		}
		AWLogInfo(@"Succeed fetch adview config in background.");
		if (self.refreshTimer) {
			[self.refreshTimer invalidate];
			self.refreshTimer = nil;
		}
		if (self.configTimer) {
			[self.configTimer invalidate];
			self.configTimer = nil;
		}
		[config removeDelegate:self];
		self.config = nil;
		self.config = self.config_noblocking;
		self.config_noblocking = nil;
		self.config.fetchBlockMode = YES;
		//will continue next set.
	}
	
  if (self.config != cfg) {
    AWLogWarn(@"AdViewView: getting adViewConfigDidReceiveConfig callback"
              @" from unknown AdViewConfig object");
    return;
  }
  AWLogInfo(@"Fetched Ad network config: %@", cfg);
  if ([delegate respondsToSelector:@selector(adViewDidReceiveConfig:)]) {
    [delegate adViewDidReceiveConfig:self];
  }
  if (cfg.adsAreOff) {
	  if (cfg.fetchByFile) {
		  AWLogInfo(@"file config ads are off, should try net config");
		  [self adViewConfigDidFail:cfg error:nil];
	  }
    else if ([delegate respondsToSelector:
                        @selector(adViewReceivedNotificationAdsAreOff:)]) {
      // to prevent self being freed before this returns, in case the
      // delegate decides to release this
      [self retain];
      [delegate adViewReceivedNotificationAdsAreOff:self];
      [self autorelease];
    }
    return;
  }

  // Perform ad network data structure build and request in main thread
  // to avoid contention
  [self performSelectorOnMainThread:
                            @selector(buildPrioritizedAdNetCfgsAndMakeRequest)
                         withObject:nil
                      waitUntilDone:NO];

  // Setup recurring timer for ad refreshes, if required
  if (config.refreshInterval > kAWMinimumTimeBetweenFreshAdRequests) {
    self.refreshTimer
      = [NSTimer scheduledTimerWithTimeInterval:config.refreshInterval
                                         target:self
                                       selector:@selector(timerRequestFreshAd)
                                       userInfo:nil
                                        repeats:YES];
  }
	
	if (config.fetchByFile) {
		self.configTimer = [NSTimer scheduledTimerWithTimeInterval:30
															target:self
														  selector:@selector(updateAdViewConfig)
														  userInfo:nil
														   repeats:NO];
	}
}

- (void)adViewConfigDidFail:(AdViewConfig *)cfg error:(NSError *)error {
	if (nil != cfg && !cfg.fetchBlockMode) {
		if (cfg != self.config_noblocking) {
			AWLogWarn(@"background AdViewView: getting adViewConfigDidReceiveConfig callback"
					  @" from unknown AdViewConfig object");			
			return;
		}
	}
	else if (self.config != nil && self.config != cfg) {
		// self.config could be nil if this is called before init is finished
		AWLogWarn(@"AdViewView: getting adViewConfigDidFail callback from unknown"
              @" AdViewConfig object");
		return;
	}

	configFetchAttempts++;
	
	SEL selAttmpt = nil;
	BOOL blockMode = YES;
	if (nil != cfg) blockMode = cfg.fetchBlockMode;
  
	if (blockMode) {
		if (configFetchAttempts < 1) selAttmpt = @selector(attemptFetchFileConfig:);
		else if (configFetchAttempts < 2) selAttmpt = @selector(attemptFetchOfflineConfig:);
		else if (configFetchAttempts < 5) selAttmpt = @selector(attemptFetchConfig:);
	} else {
		if (configFetchAttempts < 3) selAttmpt = @selector(attemptFetchConfig:);
		else if (configFetchAttempts < 4) selAttmpt = @selector(attemptFetchFileConfig:);
		else if (configFetchAttempts < 5) selAttmpt = @selector(attemptFetchOfflineConfig:);
	}
	
  if (nil != selAttmpt) {
    // schedule in run loop to avoid recursive calls to this function
    [self performSelectorOnMainThread:selAttmpt
                           withObject:[NSNumber numberWithBool:blockMode]
                        waitUntilDone:NO];
  } else {
	  if (blockMode) {
		  AWLogError(@"Failed fetching AdView config: %@", error);
		  [self notifyDelegateOfError:error];
	  } else {
		  AWLogInfo(@"failed fetch adview config in background.");
		  [config_noblocking removeDelegate:self];
		  [config_noblocking release], config_noblocking = nil; 
	  }
  }
}

- (NSURL *)adViewConfigURL {
#if SHADOW_ORG_DELEGATE_METHODS			//2010.12.24, laizhiwen	
  if ([delegate respondsToSelector:@selector(adViewConfigURL)]) {
    return [delegate adViewConfigURL];
  }
#else
	return [NSURL URLWithString:kAdViewDefaultConfigURL];
#endif
  return nil;
}

- (NSString *)adViewImpMetricBaseURLString {
    AWLogInfo(@"Report Host: %@", config.reportHost);
	if (nil != config.reportHost) {
		NSString *str = [NSString stringWithFormat:kAdViewImpMetricURLFmt,
						 config.reportHost];
		return str;
	}
	return kAdViewDefaultImpMetricURL;
}

- (NSString *)adViewClickMetricBaseURLString {
	if (nil != config.reportHost) {
		NSString *str = [NSString stringWithFormat:kAdViewClickMetricURLFmt,
						 config.reportHost];
		return str;
	}	
	return kAdViewDefaultClickMetricURL;
}

#pragma mark Active status notification callbacks

- (void)resignActive:(NSNotification *)notification {
  AWLogInfo(@"App become inactive, AdViewView will stop requesting ads");
  appInactive = YES;
}

- (void)becomeActive:(NSNotification *)notification {
  AWLogInfo(@"App become active, AdViewView will resume requesting ads");
  appInactive = NO;
}


#pragma mark AdViewDelegate helper methods

- (void)notifyDelegateOfErrorWithCode:(NSInteger)errorCode
                          description:(NSString *)desc {
  NSError *error = [[AdViewError alloc] initWithCode:errorCode
                                          description:desc];
  [self notifyDelegateOfError:error];
  [error release];
}

- (void)notifyDelegateOfError:(NSError *)error {
  [error retain];
  [lastError release];
  lastError = error;
  if ([delegate respondsToSelector:
                          @selector(adViewDidFailToReceiveAd:usingBackup:)]) {
    // to prevent self being freed before this returns, in case the
    // delegate decides to release this
    [self retain];
    [delegate adViewDidFailToReceiveAd:self usingBackup:NO];
    [self autorelease];
  }
}

#pragma mark - AdViewDeviceCollecor methods
- (NSString*) appKey
{
    if (delegate && [delegate respondsToSelector:@selector(adViewApplicationKey)]) {
        return [delegate performSelector:@selector(adViewApplicationKey)];
    } else {
        return @"";
    }
}

- (NSString*) marketChannel
{
    if (delegate && [delegate respondsToSelector:@selector(adViewApplicationPublishChannel)]) {
        return [delegate performSelector:@selector(adViewApplicationPublishChannel)];
    } else {
        return KADVIEW_PUBLISH_CHANNEL_APPSTORE;
    }
}
@end