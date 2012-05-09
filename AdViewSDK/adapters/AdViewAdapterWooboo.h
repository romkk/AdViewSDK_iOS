/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter.h"
#import "CommonADView.h"

@interface AdViewAdapterWooboo : AdViewAdNetworkAdapter <ADCommonListenerDelegate>{
}

+ (AdViewAdNetworkType)networkType;

@end
