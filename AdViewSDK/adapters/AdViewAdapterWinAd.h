/*
 * AdView:
 */

#import "AdViewAdNetworkAdapter.h"
#import "WinView.h"
#import "WinViewDelegateProtocol.h"

@interface AdViewAdapterWinAd: AdViewAdNetworkAdapter <WinViewDelegate>
@property (nonatomic, copy) NSString* winadIdString;
@property (nonatomic, retain) UIView* winadAdView;
@end
