/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter.h"
#import "KAdView.h"


/*架势无线*/

@interface AdViewAdapterKyAdView : AdViewAdNetworkAdapter <KAdViewDelegate> {

}

+ (AdViewAdNetworkType)networkType;

@end
