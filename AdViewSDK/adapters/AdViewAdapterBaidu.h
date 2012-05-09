/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter+helpers.h"
#import "BaiduMobAdView.h"

@class BaiduMobAdView;

/*baidu*/

@interface AdViewAdapterBaidu : AdViewAdNetworkAdapter <BaiduMobAdViewDelegate> {
}

+ (AdViewAdNetworkType)networkType;

@end
