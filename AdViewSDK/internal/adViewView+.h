/*

 AdViewView+.h

 Copyright 2009 AdMob, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

#import "AdViewAdNetworkAdapter.h"


@class AdViewConfigStore;


@interface AdViewViewImpl ()

// Only initializes default values for member variables
- (id)initWithDelegate:(id<AdViewDelegate>)delegate;

// Kicks off getting config from AdViewConfigStore
- (void)startGetConfig;

- (void)buildPrioritizedAdNetCfgsAndMakeRequest;
- (AdViewAdNetworkConfig *)nextNetworkCfgByPercent;
- (AdViewAdNetworkConfig *)nextNetworkCfgByPriority;
- (void)makeAdRequest:(BOOL)isFirstRequest;
- (void)reportExImpression:(NSString *)nid netType:(AdViewAdNetworkType)type;
- (void)reportExClick:(NSString *)nid netType:(AdViewAdNetworkType)type;
- (BOOL)canRefresh;
- (void)resignActive:(NSNotification *)notification;
- (void)becomeActive:(NSNotification *)notification;

- (void)notifyDelegateOfErrorWithCode:(NSInteger)errorCode
                          description:(NSString *)desc;
- (void)notifyDelegateOfError:(NSError *)error;

@property (retain) AdViewConfig *config;
@property (retain) AdViewConfig *config_noblocking;
@property (retain) NSMutableArray *prioritizedAdNetCfgs;
@property (nonatomic,retain) AdViewAdNetworkAdapter *currAdapter;
@property (nonatomic,retain) AdViewAdNetworkAdapter *lastAdapter;
@property (nonatomic,retain) NSDate *lastRequestTime;
@property (nonatomic,retain) NSTimer *refreshTimer;
@property (nonatomic,retain) NSTimer *configTimer;
@property (nonatomic,assign) AdViewConfigStore *configStore;
@property (nonatomic,retain) AWNetworkReachabilityWrapper *rollOverReachability;

@end
