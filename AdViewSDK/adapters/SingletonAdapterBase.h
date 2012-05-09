//
//  SingletonAdapterBase.h
//  AdViewSDK
//
//  Created by zhiwen on 12-1-13.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdViewAdNetworkAdapter.h"


@interface SingletonAdapterBase : NSObject {
	AdViewAdNetworkAdapter	*mAdapter;
	NSMutableArray			*mIdelViewArr;
	NSObject				*mLockObj;
}

@property (nonatomic, assign) AdViewAdNetworkAdapter	*mAdapter;
@property (nonatomic, retain) NSMutableArray			*mIdelViewArr;
@property (nonatomic, retain) NSObject					*mLockObj;

- (void)setAdapter:(AdViewAdNetworkAdapter*)adapter;
- (UIView*)getIdelAdView;
- (void)addIdelAdView:(UIView*)view;
- (BOOL)isTestMode;

- (UIView*)createAdView;


- (void)updateAdFrame:(UIView*)view;
- (BOOL) isAdViewValid:(UIView*)adView;

@end
