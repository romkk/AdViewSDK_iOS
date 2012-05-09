/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter.h"
#import "SmartMadAdView.h"

/*架势无线*/

@interface AdViewAdapterSmartMad : AdViewAdNetworkAdapter <SmartMadAdViewDelegate, SmartMadAdEventDelegate> {
}

+ (AdViewAdNetworkType)networkType;

@end
