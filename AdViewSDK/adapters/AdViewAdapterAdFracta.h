/*
 * AdView:
 */

#import "AdViewAdNetworkAdapter.h"
#import "AdFractaView.h"

@interface AdViewAdapterAdFracta: AdViewAdNetworkAdapter <AdFractaViewDelegate> {
}

@property (nonatomic, copy) NSString* adfractaIdString;
@property (nonatomic, retain) UIView* adfractaAdView;
@end
