/*

 AdViewConfig.m

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

#import <CommonCrypto/CommonDigest.h>

#import "AdViewConfig.h"
#import "AdViewError.h"
#import "AdViewAdNetworkConfig.h"
#import "AdViewLog.h"
#import "AdViewViewImpl.h"
#import "AdViewAdNetworkAdapter.h"
#import "AdViewAdNetworkRegistry.h"
#import "UIColor+AdViewConfig.h"
#import "AWNetworkReachabilityWrapper.h"

BOOL awIntVal(NSInteger *var, id val) {
  if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) {
    *var = [val integerValue];
    return YES;
  }
  return NO;
}

BOOL awFloatVal(CGFloat *var, id val) {
  if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) {
    *var = [val floatValue];
    return YES;
  }
  return NO;
}

BOOL awDoubleVal(double *var, id val) {
  if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) {
    *var = [val doubleValue];
    return YES;
  }
  return NO;
}


@implementation AdViewConfig

@synthesize appKey;
@synthesize configURL;
@synthesize adsAreOff;
@synthesize adNetworkConfigs;
@synthesize backgroundColor;
@synthesize textColor;
@synthesize refreshInterval;
@synthesize locationOn;
@synthesize bannerAnimationType;
@synthesize fullscreenWaitInterval;
@synthesize fullscreenMaxAds;
@synthesize hasConfig;
@synthesize reportHost;
@synthesize getDataDate;

@synthesize adNetworkRegistry;

@synthesize langSet;
@synthesize fetchBlockMode;
@synthesize fetchByFile;

#pragma mark -

+ (BOOL)isDeviceForeign {
	BOOL isDeviceForeign = YES;		//set the language not simple zh
	
	NSLocale *locale = [NSLocale currentLocale];
	NSString *langCode = [locale objectForKey:NSLocaleLanguageCode];//match the country's lang
	NSString *langSetCode = [[NSLocale preferredLanguages] objectAtIndex:0];
	NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
	//NSString *locId = [locale objectForKey:NSLocaleIdentifier];
	if ([countryCode isEqualToString:@"CN"]
		|| [langCode isEqualToString:@"zh"]
		|| [langSetCode isEqualToString:@"zh"]
		|| [langSetCode hasPrefix:@"zh-"]) {
		isDeviceForeign = NO;
	}
	
	AWLogInfo(@"country:%@, langSet:%@, lang:%@", countryCode, langSetCode, langCode);
	
	return isDeviceForeign;
}

- (id)initWithAppKey:(NSString *)ak delegate:(id<AdViewConfigDelegate>)delegate {
  self = [super init];
	
  if (self != nil) {
    appKey = [[NSString alloc] initWithString:ak];
    legacy = NO;
    adNetworkConfigs = [[NSMutableArray alloc] init];
    delegates = [[NSMutableArray alloc] init];
    hasConfig = NO;
    [self addDelegate:delegate];

    // object dependencies
    adNetworkRegistry = [AdViewAdNetworkRegistry sharedRegistry];

    // default values
    backgroundColor = [[UIColor alloc] initWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    textColor = [[UIColor whiteColor] retain];
    refreshInterval = 60;
    locationOn = YES;
    bannerAnimationType = AWBannerAnimationTypeRandom;
    fullscreenWaitInterval = 60;
    fullscreenMaxAds = 2;

    // config URL
    NSURL *configBaseURL = nil;
    if ([delegate respondsToSelector:@selector(adViewConfigURL)]) {
      configBaseURL = [delegate adViewConfigURL];
    }
    if (configBaseURL == nil) {
      configBaseURL = [NSURL URLWithString:kAdViewDefaultConfigURL];
    }
	  
	BOOL isDeviceForeign = [AdViewConfig isDeviceForeign];	  
	  
    configURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"?appid=%@&location=%@&appver=%d&client=1",
                                               appKey,
											   (isDeviceForeign?@"foreign":@"china"),
                                               KADVIEW_APP_VERSION]
                                relativeToURL:configBaseURL];
  }
  return self;
}

- (BOOL)addDelegate:(id<AdViewConfigDelegate>)delegate {
  for (NSValue *w in delegates) {
    id<AdViewConfigDelegate> existing = [w nonretainedObjectValue];
    if (existing == delegate) {
      return NO; // already in the list of delegates
    }
  }
  NSValue *wrapped = [NSValue valueWithNonretainedObject:delegate];
  [delegates addObject:wrapped];
  return YES;
}

- (BOOL)removeDelegate:(id<AdViewConfigDelegate>)delegate {
  NSUInteger i;
  for (i = 0; i < [delegates count]; i++) {
    NSValue *w = [delegates objectAtIndex:i];
    id<AdViewConfigDelegate> existing = [w nonretainedObjectValue];
    if (existing == delegate) {
      break;
    }
  }
  if (i < [delegates count]) {
    [delegates removeObjectAtIndex:i];
    return YES;
  }
  return NO;
}

- (void)notifyDelegatesOfFailure:(NSError *)error {
  for (NSValue *wrapped in delegates) {
    id<AdViewConfigDelegate> delegate = [wrapped nonretainedObjectValue];
    if ([delegate respondsToSelector:@selector(adViewConfigDidFail:error:)]) {
      [delegate adViewConfigDidFail:self error:error];
    }
  }
}

- (NSString *)description {
  NSString *desc = [super description];
  NSString *configs = [NSString stringWithFormat:
                       @"location_access:%d fg_color:%@ bg_color:%@ cycle_time:%lf transition:%d",
                       locationOn, textColor, backgroundColor, refreshInterval, bannerAnimationType];
  return [NSString stringWithFormat:@"%@:\n%@ networks:%@",desc,configs,adNetworkConfigs];
}

- (void)dealloc {
	[getDataDate release], getDataDate = nil;
	[reportHost release], reportHost = nil;
  [appKey release], appKey = nil;
  [configURL release], configURL = nil;
  [adNetworkConfigs release], adNetworkConfigs = nil;
  [backgroundColor release], backgroundColor = nil;
  [textColor release], textColor = nil;
  [delegates release], delegates = nil;
  [super dealloc];
}

#pragma mark parsing methods

- (BOOL)parseExtraConfig:(NSDictionary *)configDict error:(NSError **)error {
  id bgColor = [configDict objectForKey:@"background_color_rgb"];
  if (bgColor != nil && [bgColor isKindOfClass:[NSDictionary class]]) {
    [backgroundColor release];
    backgroundColor = [UIColorHelper initWithDict:(NSDictionary *)bgColor];
  }
  id txtColor = [configDict objectForKey:@"text_color_rgb"];
  if (txtColor != nil && [txtColor isKindOfClass:[NSDictionary class]]) {
    [textColor release];
    textColor = [UIColorHelper initWithDict:txtColor];
  }
  id tempVal;
  tempVal = [configDict objectForKey:@"refresh_interval"];
  if (tempVal == nil)
    tempVal = [configDict objectForKey:@"cycle_time"];
  NSInteger tempInt;
  if (tempVal && awIntVal(&tempInt, tempVal)) {
    refreshInterval = (NSTimeInterval)tempInt;
    if (refreshInterval >= 30000.0) {
      // effectively forever, set to 0
      refreshInterval = 0.0;
    }
  }
  if (awIntVal(&tempInt, [configDict objectForKey:@"location_on"])) {
    locationOn = (tempInt == 0)? NO : YES;
    // check user preference. user preference of NO trumps all
	  
    BOOL bLocationServiceEnabled = NO;
    if ([CLLocationManager respondsToSelector:
                                          @selector(locationServicesEnabled)]) {
      bLocationServiceEnabled = [CLLocationManager locationServicesEnabled];
    }
    else {
      CLLocationManager* locMan = [[CLLocationManager alloc] init];
      bLocationServiceEnabled = locMan.locationServicesEnabled;
      [locMan release], locMan = nil;
    }

    if (locationOn == YES && bLocationServiceEnabled == NO) {
      AWLogInfo(@"User disabled location services, set locationOn to NO");
      locationOn = NO;
    }
  }
  tempVal = [configDict objectForKey:@"transition"];
  if (tempVal == nil)
    tempVal = [configDict objectForKey:@"banner_animation_type"];
  if (tempVal && awIntVal(&tempInt, tempVal)) {
    switch (tempInt) {
      case 0: bannerAnimationType = AWBannerAnimationTypeNone; break;
      case 1: bannerAnimationType = AWBannerAnimationTypeFlipFromLeft; break;
      case 2: bannerAnimationType = AWBannerAnimationTypeFlipFromRight; break;
      case 3: bannerAnimationType = AWBannerAnimationTypeCurlUp; break;
      case 4: bannerAnimationType = AWBannerAnimationTypeCurlDown; break;
      case 5: bannerAnimationType = AWBannerAnimationTypeSlideFromLeft; break;
      case 6: bannerAnimationType = AWBannerAnimationTypeSlideFromRight; break;
      case 7: bannerAnimationType = AWBannerAnimationTypeFadeIn; break;
      case 8: bannerAnimationType = AWBannerAnimationTypeRandom; break;
    }
  }
  if (awIntVal(&tempInt, [configDict objectForKey:@"fullscreen_wait_interval"])) {
    fullscreenWaitInterval = tempInt;
  }
  if (awIntVal(&tempInt, [configDict objectForKey:@"fullscreen_max_ads"])) {
    fullscreenMaxAds = tempInt;
  }
	tempVal = [configDict objectForKey:@"report"];
	if (nil != tempVal) {
		[reportHost release];
		reportHost = [[NSString alloc] initWithString:tempVal];
	}
	
  return YES;
}

- (BOOL)parseLegacyConfig:(NSArray *)configArray error:(NSError **)error {
  NSMutableDictionary *adNetConfigDicts = [[NSMutableDictionary alloc] init];
  for (int i = 0; i < [configArray count]; i++) {
    id configObj = [configArray objectAtIndex:i];
    if (![configObj isKindOfClass:[NSDictionary class]]) {
      if (error != nil)
        *error = [AdViewError errorWithCode:AdViewConfigDataError
                                 description:@"Expected dictionary in config data"];
      [adNetConfigDicts release];
      return NO;
    }
    NSDictionary *configDict = (NSDictionary *)configObj;
    switch (i) {
      case 0:
        // ration map
      case 1:
        // key map
      case 2:
        // priority map
        for (id key in [configDict keyEnumerator]) {
          // format: "<network name>_<value name>" e.g. "admob_ration"
          NSString *strKey = (NSString *)key;
          if ([strKey compare:@"empty_ration"] == NSOrderedSame) {
            NSInteger empty_ration;
            if (awIntVal(&empty_ration, [configDict objectForKey:key]) && empty_ration == 100) {
              adsAreOff = YES;
              [adNetConfigDicts release];
              return YES;
            }
          }
          adsAreOff = NO;
          NSRange underScorePos = [strKey rangeOfString:@"_" options:NSBackwardsSearch];
          if (underScorePos.location == NSNotFound) {
            if (error != nil)
              *error = [AdViewError errorWithCode:AdViewConfigDataError
                                       description:[NSString stringWithFormat:
                                                    @"Expected underscore delimiter in key '%@'", strKey]];
            [adNetConfigDicts release];
            return NO;
          }
          NSString *networkName = [strKey substringToIndex:underScorePos.location];
          NSString *valueName = [strKey substringFromIndex:(underScorePos.location+1)];
          if ([networkName length] == 0) {
            if (error != nil)
              *error = [AdViewError errorWithCode:AdViewConfigDataError
                                       description:[NSString stringWithFormat:
                                                    @"Empty ad network name in key '%@'", strKey]];
            [adNetConfigDicts release];
            return NO;
          }
          if ([valueName length] == 0) {
            if (error != nil)
              *error = [AdViewError errorWithCode:AdViewConfigDataError
                                       description:[NSString stringWithFormat:
                                                    @"Empty value name in key '%@'", strKey]];
            [adNetConfigDicts release];
            return NO;
          }
          if ([networkName compare:@"dontcare"] == NSOrderedSame) {
            continue;
          }
          NSMutableDictionary *adNetConfigDict = [adNetConfigDicts objectForKey:networkName];
          if (adNetConfigDict == nil) {
            adNetConfigDict = [[NSMutableDictionary alloc] init];
            [adNetConfigDicts setObject:adNetConfigDict forKey:networkName];
            [adNetConfigDict release];
            adNetConfigDict = [adNetConfigDicts objectForKey:networkName];
          }
          NSString *properValueName;
          if ([valueName compare:@"ration"] == NSOrderedSame) {
            properValueName = AWAdNetworkConfigKeyWeight;
          }
          else if ([valueName compare:@"key"] == NSOrderedSame) {
            properValueName = AWAdNetworkConfigKeyCred;
          }
          else if ([valueName compare:@"key2"] == NSOrderedSame) {
			  properValueName = AWAdNetworkConfigKey2Cred;
          }
          else if ([valueName compare:@"key3"] == NSOrderedSame) {
			  properValueName = AWAdNetworkConfigKey3Cred;
          }			
          else if ([valueName compare:@"priority"] == NSOrderedSame) {
            properValueName = AWAdNetworkConfigKeyPriority;
          }
          else {
            properValueName = valueName;
          }
          [adNetConfigDict setObject:[configDict objectForKey:key]
                              forKey:properValueName];
        }
        break; // ad network config maps

      case 3:
        // general config map
        if (![self parseExtraConfig:configDict error:error]) {
          return NO;
        }
        break; // general config map
      default:
        AWLogWarn(@"Ignoring element at index %d in legacy config", i);
        break;
    } // switch (i)
  } // loop configArray

  // adview_ special handling
  NSMutableDictionary *adRolloConfig = [adNetConfigDicts objectForKey:@"adrollo"];
  if (adRolloConfig != nil) {
    AWLogInfo(@"Processing AdRollo config %@", adRolloConfig);
    NSMutableArray *adViewNetworkConfigs = [[NSMutableArray alloc] init];;
    for (NSString *netname in [adNetConfigDicts keyEnumerator]) {
      if (![netname hasPrefix:@"adview_"]) continue;
      [adViewNetworkConfigs addObject:[adNetConfigDicts objectForKey:netname]];
    }
    if ([adViewNetworkConfigs count] > 0) {
      // split the ration evenly, use same credentials
      NSInteger ration = [[adRolloConfig objectForKey:AWAdNetworkConfigKeyWeight] integerValue];
      ration = ration/[adViewNetworkConfigs count];
      for (NSMutableDictionary *cd in adViewNetworkConfigs) {
        [cd setObject:[NSNumber numberWithInteger:ration]
               forKey:AWAdNetworkConfigKeyWeight];
        [cd setObject:[adRolloConfig objectForKey:AWAdNetworkConfigKeyCred]
               forKey:AWAdNetworkConfigKeyCred];
		[cd setObject:[adRolloConfig objectForKey:AWAdNetworkConfigKey2Cred]
			   forKey:AWAdNetworkConfigKey2Cred];
		[cd setObject:[adRolloConfig objectForKey:AWAdNetworkConfigKey3Cred]
			   forKey:AWAdNetworkConfigKey3Cred];		  
      }
    }
    [adViewNetworkConfigs release];
  }

  NSInteger totalWeight = 0;
  for (id networkName in [adNetConfigDicts keyEnumerator]) {
    NSString *netname = (NSString *)networkName;
    if ([netname compare:@"adrollo"] == NSOrderedSame) {
      // skip adrollo, was used for "adview_" networks
      continue;
    }
    NSMutableDictionary *adNetConfigDict = [adNetConfigDicts objectForKey:netname];

    // set network type for legacy
    NSInteger networkType = 0;
    if ([netname caseInsensitiveCompare:@"admob"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeAdMob;
    }
    else if ([netname caseInsensitiveCompare:@"jumptap"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeJumpTap;
    }
    else if ([netname caseInsensitiveCompare:@"videoegg"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeVideoEgg;
    }
    else if ([netname caseInsensitiveCompare:@"medialets"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeMedialets;
    }
    else if ([netname caseInsensitiveCompare:@"liverail"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeLiveRail;
    }
    else if ([netname caseInsensitiveCompare:@"millennial"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeMillennial;
    }
    else if ([netname caseInsensitiveCompare:@"greystripe"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeGreyStripe;
    }
    else if ([netname caseInsensitiveCompare:@"quattro"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeQuattro;
    }
    else if ([netname caseInsensitiveCompare:@"custom"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeCustom;
    }
    else if ([netname caseInsensitiveCompare:@"adview_10"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeAdView10;
    }
    else if ([netname caseInsensitiveCompare:@"mobclix"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeMobClix;
    }
    else if ([netname caseInsensitiveCompare:@"adview_12"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeMdotM;
    }
    else if ([netname caseInsensitiveCompare:@"adview_13"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeAdView13;
    }
    else if ([netname caseInsensitiveCompare:@"google_adsense"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeGoogleAdSense;
    }
    else if ([netname caseInsensitiveCompare:@"google_doubleclick"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeGoogleDoubleClick;
    }
    else if ([netname caseInsensitiveCompare:@"generic"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeGeneric;
    }
    else if ([netname caseInsensitiveCompare:@"inmobi"] == NSOrderedSame) {
      networkType = AdViewAdNetworkTypeInMobi;
    }
    else if ([netname caseInsensitiveCompare:@"Wooboo"] == NSOrderedSame) {
		networkType = AdViewAdNetworkTypeWOOBOO;
    }
    else if ([netname caseInsensitiveCompare:@"Youmi"] == NSOrderedSame) {
		networkType = AdViewAdNetworkTypeYOUMI;
    }
    else if ([netname caseInsensitiveCompare:@"KuaiYou"] == NSOrderedSame) {
		networkType = AdViewAdNetworkTypeKUAIYOU;
    }
	  
    else {
      AWLogWarn(@"Unrecognized ad network '%@' in legacy config, ignored", netname);
      continue;
    }

    [adNetConfigDict setObject:netname forKey:AWAdNetworkConfigKeyName];
    [adNetConfigDict setObject:[NSString stringWithFormat:@"%d", networkType]
                        forKey:AWAdNetworkConfigKeyNID];
    [adNetConfigDict setObject:[NSNumber numberWithInteger:networkType]
                        forKey:AWAdNetworkConfigKeyType];

    AdViewError *adNetConfigError = nil;
    AdViewAdNetworkConfig *adNetConfig =
      [[AdViewAdNetworkConfig alloc] initWithDictionary:adNetConfigDict
                                       adNetworkRegistry:adNetworkRegistry
                                                   error:&adNetConfigError];
    if (adNetConfig != nil) {
      [adNetworkConfigs addObject:adNetConfig];
      totalWeight += adNetConfig.trafficPercentage;
      [adNetConfig release];
    }
    else {
      AWLogWarn(@"Cannot create ad network config from %@: %@", adNetConfigDict,
                adNetConfigError != nil? [adNetConfigError localizedDescription]:@"");
    }
  } // for each ad network name

  if (totalWeight == 0) {
    adsAreOff = YES;
  }

  [adNetConfigDicts release];
  return YES;
}

- (BOOL)isMatchLangSet:(AdViewAdNetworkConfig*)config {
	if (self.langSet == LangSetType_None) return YES;	//skip the check
	
	BOOL isDeviceForeign = [AdViewConfig isDeviceForeign];
	
	BOOL isAdForeign = isForeignAd(config.networkType);
	//check by config's network type
	
	if (self.langSet == LangSetType_Foreign) {
		if (isDeviceForeign) return isAdForeign;
		return YES;				//skip the check
	}
	
	if (self.langSet == LangSetType_Separated) {
		return !(isDeviceForeign ^ isAdForeign);
	}
	
	return YES;	//skip
}

- (BOOL)parseNewConfig:(NSDictionary *)configDict error:(NSError **)error {
  id extra = [configDict objectForKey:@"extra"];
  if (extra != nil && [extra isKindOfClass:[NSDictionary class]]) {
    NSDictionary *extraDict = extra;
    if (![self parseExtraConfig:extraDict error:error]) {
      return NO;
    }
  }
  else {
    AWLogWarn(@"No extra info dict in ad network config");
  }

  id rations = [configDict objectForKey:@"rations"];
  double totalWeight = 0.0;
  if (rations != nil && [rations isKindOfClass:[NSArray class]]) {
    if ([(NSArray *)rations count] == 0) {
      adsAreOff = YES;
      return YES;
    }
    adsAreOff = NO;
    for (id c in (NSArray *)rations) {
      if (![c isKindOfClass:[NSDictionary class]]) {
        AWLogWarn(@"Element in rations array is not a dictionary %@ in ad network config",c);
        continue;
      }
      AdViewError *adNetConfigError = nil;
      AdViewAdNetworkConfig *adNetConfig =
        [[AdViewAdNetworkConfig alloc] initWithDictionary:(NSDictionary *)c
                                         adNetworkRegistry:adNetworkRegistry
                                                     error:&adNetConfigError];
		BOOL bIsLangMatch = YES;
		if (nil != adNetConfig) 
			bIsLangMatch = [self isMatchLangSet:adNetConfig];
	  if (adNetConfig != nil && bIsLangMatch) {
        [adNetworkConfigs addObject:adNetConfig];
        totalWeight += adNetConfig.trafficPercentage;
        [adNetConfig release];
      }
      else {
        AWLogWarn(@"Cannot create ad network config from %@: %@", c,
                  adNetConfigError != nil? [adNetConfigError localizedDescription]:@"");
		  if (!bIsLangMatch) AWLogWarn(@"for ad country code not match");
      }
    }
  }
  else {
    AWLogError(@"No rations array in ad network config");
  }

  if (totalWeight == 0.0) {
    adsAreOff = YES;
  }

  return YES;
}

- (BOOL)parseConfig:(NSData *)data error:(NSError **)error {
  if (hasConfig) {
    *error = [AdViewError errorWithCode:AdViewConfigDataError
                             description:@"Already has config, will not parse"];
    return NO;
  }
	[getDataDate release];
	getDataDate = [[NSDate alloc] init];
	
  NSError *jsonError = nil;
  id parsed = [[CJSONDeserializer deserializer] deserialize:data error:&jsonError];
  if (parsed == nil) {
    if (error != nil)
      *error = [AdViewError errorWithCode:AdViewConfigParseError
                               description:@"Error parsing config JSON from server"
                           underlyingError:jsonError];
    return NO;
  }
  if ([parsed isKindOfClass:[NSArray class]]) {
    // pre-open-source AdView/AdRollo config
    legacy = YES;
    if (![self parseLegacyConfig:(NSArray *)parsed error:error]) {
      return NO;
    }
  }
  else if ([parsed isKindOfClass:[NSDictionary class]]) {
    // open-source AdView config
    if (![self parseNewConfig:(NSDictionary *)parsed error:error]) {
      return NO;
    }
  }
  else {
    if (error != nil)
      *error = [AdViewError errorWithCode:AdViewConfigDataError
                               description:@"Expected top-level dictionary in config data"];
    return NO;
  }

  // parse success
  hasConfig = YES;

  // notify delegates of success
  for (NSValue *wrapped in delegates) {
    id<AdViewConfigDelegate> delegate = [wrapped nonretainedObjectValue];
    if ([delegate respondsToSelector:@selector(adViewConfigDidReceiveConfig:)]) {
      [delegate adViewConfigDidReceiveConfig:self];
    }
  }

  return YES;
}

@end
