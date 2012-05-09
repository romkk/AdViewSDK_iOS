//
//  AWInterstitialAdController.h
//  Copyright 2011 Adwo.com All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWAdView.h"

enum 
{
	InterstitialCloseButtonTypeDefault,
	InterstitialCloseButtonTypeNone
};
typedef NSUInteger InterstitialCloseButtonType;

enum 
{
	InterstitialOrientationTypePortrait,
	InterstitialOrientationTypeLandscape,
	InterstitialOrientationTypeBoth
};
typedef NSUInteger InterstitialOrientationType;

@protocol AWInterstitialAdControllerDelegate;

@interface AWInterstitialAdController : UIViewController <AWAdViewDelegate>
{
	// Previous state of the status bar, before the interstitial appears.
	BOOL _statusBarWasHidden;
	
	// Previous state of the nav bar, before the interstitial appears.
	BOOL _navigationBarWasHidden;
	
	// Whether the interstitial is fully loaded.
	BOOL _ready;
	
	// Underlying ad view used for the interstitial.
	AWAdView *_adView;
	//UIWebView *_adView;
	// Reference to the view controller that is presenting this interstitial.
	UIViewController<AWInterstitialAdControllerDelegate> *_parent;
	
	// The ad unit ID.
	NSString *_adUnitId;
	
	// Size of the interstitial ad. Defaults to fill the entire screen.
	CGSize _adSize;
    SInt8 _adIdType;
    SInt8 _adPayType;
    
	
	// Determines what kind of close button we want to display.
	InterstitialCloseButtonType _closeButtonType;
	
	// Determines the allowed orientations for the interstitial.
	InterstitialOrientationType _orientationType;
	
	// Button used to dismiss the interstitial.
	UIButton *_closeButton;
}

@property (nonatomic, readonly, assign) BOOL ready;
@property (nonatomic, assign) id<AWInterstitialAdControllerDelegate> parent;
@property (nonatomic, copy) NSString *adUnitId;

+ (NSMutableArray *)sharedInterstitialAdControllers;
+ (AWInterstitialAdController *)interstitialAdControllerForAdwoPid:(NSString *)ID adIdType:(SInt8 )adIdType adTestMode:(SInt8)adTestMode;
+ (void)removeSharedInterstitialAdController:(AWInterstitialAdController *)controller;
- (void)loadAd;
- (void)presentInterstitialFromViewController:(UIViewController *)viewController;

@end

@protocol AWInterstitialAdControllerDelegate <AWAdViewDelegate>
@required

- (void)dismissInterstitial:(AWInterstitialAdController *)interstitial;

@optional

- (void)interstitialDidLoadAd:(AWInterstitialAdController *)interstitial;
- (void)interstitialDidFailToLoadAd:(AWInterstitialAdController *)interstitial;
- (void)interstitialWillAppear:(AWInterstitialAdController *)interstitial;
@end

