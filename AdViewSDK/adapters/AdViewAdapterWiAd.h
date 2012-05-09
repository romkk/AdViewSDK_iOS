/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter.h"
#import "WiAdView.h"

@class WiAdView;

/*易传媒*/

@interface AdViewAdapterWiAd : AdViewAdNetworkAdapter <WiAdViewDelegate> {

}

+ (AdViewAdNetworkType)networkType;

@end
