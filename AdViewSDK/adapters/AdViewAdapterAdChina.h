/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter.h"
#import "AdChinaBannerViewDelegateProtocol.h"

@class AdChinaView;
@class AdViewAdapterAdChinaImpl;

/*易传媒*/

@interface AdViewAdapterAdChina : AdViewAdNetworkAdapter {
	AdViewAdapterAdChinaImpl	*mDelegate;
}

+ (AdViewAdNetworkType)networkType;

@end