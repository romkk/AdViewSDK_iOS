/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter.h"
#import "VponAdOn.h"

@class AdOnView;

/*架势无线*/

@interface AdViewAdapterVpon : AdViewAdNetworkAdapter <VponAdOnDelegate> {

}

+ (AdViewAdNetworkType)networkType;

@end
