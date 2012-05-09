/*
 * AdView:
 */

#import "AdViewAdNetworkAdapter.h"
#import "UMAdBannerView.h"
#import "UMAdManager.h"

@interface AdViewAdapterUMAd : AdViewAdNetworkAdapter <UMADAppDelegate, UMAdADBannerViewDelegate, UMWebViewDelegate> {
}

@property (nonatomic, copy) NSString* umadClientIdString;
@property (nonatomic, copy) NSString* umadSlotIdString;

@end
