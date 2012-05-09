//
//  AdView.h
//  AdOn
//
//  Created by Shark on 2010/6/2.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AdOnPlatform.h"

#define ADON_SIZE_320x48     CGSizeMake(320,48)

#define ADON_SIZE_320x270    CGSizeMake(320,270)

#define ADON_SIZE_488x80     CGSizeMake(488,80)

#define ADON_SIZE_748x110    CGSizeMake(748,110)

@protocol VponAdOnDelegate; 

@interface VponAdOn : NSObject {

    id<VponAdOnDelegate> adOnDelegate;
    BOOL isVponLogo;
}
@property (nonatomic, retain) id<VponAdOnDelegate> adOnDelegate;
@property (nonatomic, readwrite) BOOL isVponLogo;

#pragma mark Initialization
+ (VponAdOn *)initializationLatitude:(CGFloat)lat longtitude:(CGFloat)lon platform:(Platform)platform;
#pragma mark Instance
+ (VponAdOn *)sharedInstance;
#pragma mark for Vpon
- (NSArray *)requestDelegate:(id<VponAdOnDelegate>)delegate LicenseKey:(NSArray *)arrayLicenseKey size:(CGSize)size;
#pragma mark for adwhirl
- (UIViewController *)adwhirlRequestDelegate:(id<VponAdOnDelegate>)delegate licenseKey:(NSString *)licenseKey size:(CGSize)size;
#pragma mark return Vpon version
- (NSString *)versionVpon;
#pragma mark return plat
- (Platform)platformVpon;
@end

@protocol VponAdOnDelegate <NSObject>

@optional

#pragma mark 回傳點擊點廣是否有效
- (void)clickAd:(UIViewController *)bannerView valid:(BOOL)isValid withLicenseKey:(NSString *)adLicenseKey;
#pragma mark 回傳Vpon廣告抓取成功
- (void)onRecevieAd:(UIViewController *)bannerView withLicenseKey:(NSString *)licenseKey;
#pragma mark 回傳Vpon廣告抓取失敗
- (void)onFailedToRecevieAd:(UIViewController *)bannerView withLicenseKey:(NSString *)licenseKey;

@end
