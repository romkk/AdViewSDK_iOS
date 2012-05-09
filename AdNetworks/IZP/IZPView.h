//
//  IZPADView.h
//  IZPADView
//
//  Created by Tang Gang on 11-4-12.
//  Copyright 2011 izp. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol IZPDelegate;

@interface IZPView : UIView

@property (nonatomic, copy) NSString * productID;

@property (nonatomic,assign)BOOL isDev;

@property (nonatomic,assign)id<IZPDelegate> delegate;

@property (nonatomic,copy)NSString* adType;

- (void)startAdExchange;

- (void)stopAdExchange;

@end

