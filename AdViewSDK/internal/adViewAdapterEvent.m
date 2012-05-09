/*

 AdViewAdapterEvent.m

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

#import "AdViewAdapterEvent.h"
#import "AdViewViewImpl.h"
#import "AdViewLog.h"
#import "AdViewAdNetworkAdapter+Helpers.h"
#import "AdViewAdNetworkRegistry.h"
#import "AdViewAdNetworkConfig.h"

@implementation AdViewAdapterEvent

+ (AdViewAdNetworkType)networkType {
	return AdViewAdNetworkTypeEvent;
}

+ (void)load {
	[[AdViewAdNetworkRegistry sharedRegistry] registerClass:self];
}

- (void)getAd {
	NSArray *eventKeys = [networkConfig.pubId componentsSeparatedByString:@"|;|"];
	NSString *eventSelectorStr = [eventKeys objectAtIndex:1];
	SEL eventSelector = NSSelectorFromString(eventSelectorStr);

	if ([adViewDelegate respondsToSelector:eventSelector]) {
		[adViewDelegate performSelector:eventSelector];
		[adViewView adapterDidFinishAdRequest:self];
	}
	else {
    NSString *eventSelectorColonStr = [NSString stringWithFormat:@"%@:", eventSelectorStr];
    SEL eventSelectorColon = NSSelectorFromString(eventSelectorColonStr);
    if ([adViewDelegate respondsToSelector:eventSelectorColon]) {
      [adViewDelegate performSelector:eventSelectorColon withObject:adViewView];
      [adViewView adapterDidFinishAdRequest:self];
    }
    else {
      AWLogWarn(@"Delegate does not implement function %@ nor %@", eventSelectorStr, eventSelectorColonStr);
      [adViewView adapter:self didFailAd:nil];
    }
	}
}

- (void)stopBeingDelegate {
  // Nothing to do
}

- (void)dealloc {
	[super dealloc];
}

@end
