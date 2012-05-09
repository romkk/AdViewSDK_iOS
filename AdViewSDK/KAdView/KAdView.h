#import <UIKit/UIKit.h>

@class KAdView;

@protocol KAdViewDelegate <NSObject>

-(UIColor*) adTextColor;
-(UIColor*) adBackgroundColor;
-(void) didReceivedAd: (KAdView*) adView;
-(void) didFailToReceiveAd: (KAdView*) adView;

-(NSString*) kAdViewHost;
-(int)	autoRefreshInterval;

@required

-(NSString*) appId;
-(BOOL) testMode;

@end

@interface KAdView : UIView

#define KADVIEW_SIZE_320x44		CGSizeMake(320, 44)
#define KADVIEW_SIZE_480x44		CGSizeMake(480, 44)
#define KADVIEW_SIZE_320x270	CGSizeMake(320, 270)
#define KADVIEW_SIZE_480x80		CGSizeMake(480, 80)
#define KADVIEW_SIZE_760x110	CGSizeMake(760, 110)

@property (nonatomic, assign) id<KAdViewDelegate> delegate;

+(KAdView*) requestOfSize: (CGSize) size withDelegate: (id<KAdViewDelegate>) delegate;
+(KAdView*) requestWithDelegate: (id<KAdViewDelegate>) delegate;
+(NSString*) sdkVersion;

-(void) pauseRequestAd;
-(void) resumeRequestAd;

@end
