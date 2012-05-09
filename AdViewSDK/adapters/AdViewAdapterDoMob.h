/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter+helpers.h"
#import "DoMobDelegateProtocol.h"

@class DoMobView;

/*架势无线*/

@interface AdViewAdapterDoMob : AdViewAdNetworkAdapter <DoMobDelegate> {

}

+ (AdViewAdNetworkType)networkType;

@end
