//
//  File: AdMoGoAdapterIZP.h
//  Project: AdsMOGO iOS SDK
//  Version: 1.0.6
//
//  Copyright 2011 AdsMogo.com. All rights reserved.
//

#import "AdViewAdNetworkAdapter.h"
#import "IZPView.h"
#import "IZPDelegate.h"

@interface AdViewAdapterIZP : AdViewAdNetworkAdapter <IZPDelegate> {
    NSTimer *timer;
}
- (void)loadAdTimeOut:(NSTimer*)theTimer;
@end
