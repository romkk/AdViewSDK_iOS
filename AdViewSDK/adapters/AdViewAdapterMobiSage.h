/*

Adview .
 
*/

#import "AdViewAdNetworkAdapter.h"
#import "mobiSageSDK.h"

/**/

@interface AdViewAdapterMobiSage : AdViewAdNetworkAdapter {
@private
    UIView* adViewInternal;
    UIView* mobiSageAdView;
}

+ (AdViewAdNetworkType)networkType;
@property (nonatomic, retain) UIView* adViewInternal;
@property (nonatomic, retain) UIView* mobiSageAdView;

@end
