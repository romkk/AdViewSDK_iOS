/*
 
 Adview .
 2012-04-12
 */

#import "AdViewAdNetworkAdapter.h"
#import "MobWinSpotViewDelegate.h"

@interface AdViewAdapterMobWin : AdViewAdNetworkAdapter <MobWinSpotViewDelegate> {
	
}

+ (AdViewAdNetworkType)networkType;

@end
