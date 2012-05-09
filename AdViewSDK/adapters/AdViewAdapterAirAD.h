/*
 
 Adview .
 2012-04-12
 */

#import "AdViewAdNetworkAdapter.h"
#import "airADViewDelegate.h"

@interface AdViewAdapterAirAD : AdViewAdNetworkAdapter <airADViewDelegate> {
	
}

+ (AdViewAdNetworkType)networkType;

@end
