//
//  LmmobADBannerView.h
//  Lmmob
//
//  Created by Zhang Kerberos on 11-9-22.
//  Copyright 2011年 LM Mob. All rights reserved.
//

#import <UIKit/UIKit.h>


@class LmmobAdBannerView;

@protocol LmmobAdBannerViewDelegate <NSObject>
@optional
- (void) lmmobAdBannerViewDidReceiveAd: (LmmobAdBannerView*) bannerView;
- (void) lmmobAdBannerView: (LmmobAdBannerView*) bannerView didFailReceiveBannerADWithError: (NSError*) error;
- (void) lmmobAdBannerViewWillPresentScreen: (LmmobAdBannerView*) bannerView;
- (void) lmmobAdBannerViewDidPresentScreen: (LmmobAdBannerView*) bannerView;
- (void) lmmobAdBannerViewWillDismissScreen: (LmmobAdBannerView*) bannerView;
- (void) lmmobAdBannerViewDidDismissScreen: (LmmobAdBannerView*) bannerView;
- (NSUInteger) lmmobAdBannerViewSetSPECID: (LmmobAdBannerView*) bannerView;
@end

@interface LmmobAdBannerView : UIView
@property (nonatomic, copy) NSString* appVersionString;
@property (nonatomic, assign) NSUInteger  specId;
@property (nonatomic, copy) NSString* adPositionIdString;
@property (nonatomic, assign) UIViewController* rootViewController;
@property (nonatomic, assign) id<LmmobAdBannerViewDelegate> delegate;
@property (nonatomic, assign) NSUInteger autoRefreshAdTimeOfSeconds;

- (id) initWithAdPosition: (NSString*) adPositionId WithSPECID: (NSUInteger) specID withAppVersion: (NSString*) appVersion;
- (id) initWithAdPosition: (NSString*) adPositionId withAppVersion: (NSString*) appVersion;
- (void) requestBannerAd;

@end
