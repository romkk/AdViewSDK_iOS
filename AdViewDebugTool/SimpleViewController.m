/*

 SimpleViewController.m

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

#import "AdViewSDK_SampleAppDelegate.h"
#import "SimpleViewController.h"
#import "AdViewView.h"
#import "SampleConstants.h"
#import "ModalViewController.h"
#import "AdViewLog.h"

#define SIMPVIEW_BUTTON_1_TAG 607701
#define SIMPVIEW_BUTTON_2_TAG 607702
#define SIMPVIEW_BUTTON_3_TAG 607703
#define SIMPVIEW_BUTTON_4_TAG 607704
#define SIMPVIEW_SWITCH_1_TAG 706613
#define SIMPVIEW_LABEL_1_TAG 7066130
#define SIMPVIEW_BUTTON_1_OFFSET 46
#define SIMPVIEW_BUTTON_2_OFFSET 46
#define SIMPVIEW_BUTTON_3_OFFSET 66
#define SIMPVIEW_BUTTON_4_OFFSET 86
#define SIMPVIEW_SWITCH_1_OFFSET 69
#define SIMPVIEW_LABEL_1_OFFSET 43
#define SIMPVIEW_LABEL_1_OFFSETX 60
#define SIMPVIEW_LABEL_OFFSET 94
#define SIMPVIEW_LABEL_HDIFF 45

@implementation SimpleViewController

@synthesize adView;

- (id)init {
  if (self = [super initWithNibName:@"SimpleViewController" bundle:nil]) {
    currLayoutOrientation = UIInterfaceOrientationPortrait; // nib file defines a portrait view
    self.title = @"Simple View";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.adView = [AdViewView requestAdViewViewWithDelegate:self];
  self.adView.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
  [self.view addSubview:self.adView];

  if (getenv("ADVIEW_FAKE_DARTS")) {
    // To make ad network selection deterministic
    const char *dartcstr = getenv("ADVIEW_FAKE_DARTS");
    NSArray *rawdarts = [[NSString stringWithUTF8String:dartcstr]
                                            componentsSeparatedByString:@" "];
    NSMutableArray *darts
                = [[NSMutableArray alloc] initWithCapacity:[rawdarts count]];
    for (NSString *dartstr in rawdarts) {
      if ([dartstr length] == 0) {
        continue;
      }
      [darts addObject:[NSNumber numberWithDouble:[dartstr doubleValue]]];
    }
    self.adView.testDarts = darts;
  }

  UIDevice *device = [UIDevice currentDevice];
  if ([device respondsToSelector:@selector(isMultitaskingSupported)] &&
      [device isMultitaskingSupported]) {
#ifdef __IPHONE_4_0
    [[NSNotificationCenter defaultCenter]
                      addObserver:self
                         selector:@selector(enterForeground:)
                             name:UIApplicationWillEnterForegroundNotification
                           object:nil];
#endif
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self adjustLayoutToOrientation:self.interfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io {
  return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.adView rotateToOrientation:toInterfaceOrientation];
  [self adjustAdSize];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)io
                                         duration:(NSTimeInterval)duration {
  [self adjustLayoutToOrientation:io];
}

- (void)adjustLayoutToOrientation:(UIInterfaceOrientation)newOrientation {
  UIView *button1 = [self.view viewWithTag:SIMPVIEW_BUTTON_1_TAG];
  UIView *button2 = [self.view viewWithTag:SIMPVIEW_BUTTON_2_TAG];
  UIView *button3 = [self.view viewWithTag:SIMPVIEW_BUTTON_3_TAG];
  UIView *button4 = [self.view viewWithTag:SIMPVIEW_BUTTON_4_TAG];
  UIView *switch1 = [self.view viewWithTag:SIMPVIEW_SWITCH_1_TAG];
  UIView *label1 = [self.view viewWithTag:SIMPVIEW_LABEL_1_TAG];
  assert(button1 != nil);
  assert(button2 != nil);
  assert(button3 != nil);
  assert(button4 != nil);
  assert(switch1 != nil);
  assert(label1 != nil);
  if (UIInterfaceOrientationIsPortrait(currLayoutOrientation)
      && UIInterfaceOrientationIsLandscape(newOrientation)) {
    CGPoint newCenter = button1.center;
    newCenter.y -= SIMPVIEW_BUTTON_1_OFFSET;
    button1.center = newCenter;
    newCenter = button2.center;
    newCenter.y -= SIMPVIEW_BUTTON_2_OFFSET;
    button2.center = newCenter;
    newCenter = button3.center;
    newCenter.y -= SIMPVIEW_BUTTON_3_OFFSET;
    button3.center = newCenter;
    newCenter = button4.center;
    newCenter.y -= SIMPVIEW_BUTTON_4_OFFSET;
    button4.center = newCenter;
    newCenter = switch1.center;
    newCenter.y -= SIMPVIEW_SWITCH_1_OFFSET;
    switch1.center = newCenter;
    newCenter = label1.center;
    newCenter.y -= SIMPVIEW_LABEL_1_OFFSET;
    newCenter.x += SIMPVIEW_LABEL_1_OFFSETX;
    label1.center = newCenter;
    CGRect newFrame = self.label.frame;
    newFrame.size.height -= 45;
    newFrame.origin.y -= SIMPVIEW_LABEL_OFFSET;
    self.label.frame = newFrame;
  }
  else if (UIInterfaceOrientationIsLandscape(currLayoutOrientation)
           && UIInterfaceOrientationIsPortrait(newOrientation)) {
    CGPoint newCenter = button1.center;
    newCenter.y += SIMPVIEW_BUTTON_1_OFFSET;
    button1.center = newCenter;
    newCenter = button2.center;
    newCenter.y += SIMPVIEW_BUTTON_2_OFFSET;
    button2.center = newCenter;
    newCenter = button3.center;
    newCenter.y += SIMPVIEW_BUTTON_3_OFFSET;
    button3.center = newCenter;
    newCenter = button4.center;
    newCenter.y += SIMPVIEW_BUTTON_4_OFFSET;
    button4.center = newCenter;
    newCenter = switch1.center;
    newCenter.y += SIMPVIEW_SWITCH_1_OFFSET;
    switch1.center = newCenter;
    newCenter = label1.center;
    newCenter.y += SIMPVIEW_LABEL_1_OFFSET;
    newCenter.x -= SIMPVIEW_LABEL_1_OFFSETX;
    label1.center = newCenter;
    CGRect newFrame = self.label.frame;
    newFrame.size.height += 45;
    newFrame.origin.y += SIMPVIEW_LABEL_OFFSET;
    self.label.frame = newFrame;
  }
  currLayoutOrientation = newOrientation;
}

- (void)adjustAdSize {
  [UIView beginAnimations:@"AdResize" context:nil];
  [UIView setAnimationDuration:0.7];
  CGSize adSize = [adView actualAdSize];
  CGRect newFrame = adView.frame;
  newFrame.size.height = adSize.height;
  newFrame.size.width = adSize.width;
  newFrame.origin.x = (self.view.bounds.size.width - adSize.width)/2;
  adView.frame = newFrame;
  [UIView commitAnimations];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
  // remove all notification for self
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UILabel *)label {
  return (UILabel *)[self.view viewWithTag:1337];
}

- (void)dealloc {
  self.adView.delegate = nil;
  self.adView = nil;
  [super dealloc];
}

#pragma mark Button handlers

- (IBAction)requestNewAd:(id)sender {
  self.label.text = @"Request New Ad pressed! Requesting...";
  [adView requestFreshAd];
}

- (IBAction)requestNewConfig:(id)sender {
  self.label.text = @"Request New Config pressed! Requesting...";
  [adView updateAdViewConfig];
}

- (IBAction)rollOver:(id)sender {
  self.label.text = @"Roll Over pressed! Requesting...";
  [adView rollOver];
}

- (IBAction)showModalView:(id)sender {
  ModalViewController *modalViewController = [[[ModalViewController alloc] init] autorelease];
  [self presentModalViewController:modalViewController animated:YES];
}

- (IBAction)toggleRefreshAd:(id)sender {
  UISwitch *switch1 = (UISwitch *)[self.view viewWithTag:SIMPVIEW_SWITCH_1_TAG];
  if (switch1.on) {
    [adView startAutoRefresh];
  }
  else {
    [adView stopAutoRefresh];
  }
}

#pragma mark AdViewDelegate methods

- (NSString *)adViewApplicationKey {
  return kSampleAppKey;
}

- (NSString *)BaiDuApIDString {
    return @"2f952126";				//@"debug";
}

- (NSString *)BaiDuApSpecString{
	//spec string for baidu
	return @"debug";		//2f952126_e498eab7
}

#if 0
- (NSString *)kuaiYouApIDString {//application id for kuaiYou
	return @"PMZTo0g20101117421215";
}

- (NSString *)youMiApIDString { //application id for youmi
	return @"6e9e6d15741495b6";
}

- (NSString *)woobooApIDString { //application id for wooboo
	return @"afc507fbcab54cd2b56beacaba74efdc";
}

- (NSString *)admobPublisherID {// your Publisher ID from Admob.
	return @"a14cf36f8a6185d";
}

- (NSString *)millennialMediaApIDString{ // your ApID string from Millennial Media.
	return @"15062";
}

- (NSString *)youMiApSecretString { //application secret for youmi
	return @"90d29d1be5d71a7c";
}

- (NSString *)adChinaApIDString {  //application id for adChina
	return @"69329";
}

- (NSString *)caseeApIDString{  //application id for casee
	return @"";
}

- (NSString *)WiAdApIDString{	//application id for WiYun
	return @"";
}

#endif

- (UIViewController *)viewControllerForPresentingModalView {
	//return self;
  return [((AdViewSDK_SampleAppDelegate *)[[UIApplication sharedApplication] delegate]) navigationController];
}

- (void)adViewDidReceiveAd:(AdViewView *)adViewView {
  self.label.text = [NSString stringWithFormat:
                     @"Got ad from %@, size %@",
                     [adViewView mostRecentNetworkName],
                     NSStringFromCGSize([adViewView actualAdSize])];
	AWLogInfo(@"height:%f", CGRectGetHeight(adViewView.bounds));	
  [self adjustAdSize];
}

- (void)adViewStartGetAd:(AdViewView *)adViewView {
	self.label.text = [NSString stringWithFormat:
					   @"Go to ad %@, size %@",
					   [adViewView mostRecentNetworkName],
					   NSStringFromCGSize([adViewView actualAdSize])];
	[self adjustAdSize];	
}

- (void)adViewDidFailToReceiveAd:(AdViewView *)adViewView usingBackup:(BOOL)yesOrNo {
  self.label.text = [NSString stringWithFormat:
                     @"Failed to receive ad from %@, %@. Error: %@",
                     [adViewView mostRecentNetworkName],
                     yesOrNo? @"will use backup" : @"will NOT use backup",
                     adViewView.lastError == nil? @"no error" : [adViewView.lastError localizedDescription]];
}

- (void)adViewReceivedGenericRequest:(AdViewView *)adViewView {
  UILabel *replacement = [[UILabel alloc] initWithFrame:KADVIEW_DETAULT_FRAME];
  replacement.backgroundColor = [UIColor redColor];
  replacement.textColor = [UIColor whiteColor];
  replacement.textAlignment = UITextAlignmentCenter;
  replacement.text = @"Generic Notification";
  [adViewView replaceBannerViewWith:replacement];
  [replacement release];
  [self adjustAdSize];
  self.label.text = @"Generic Notification";
}

- (void)adViewReceivedNotificationAdsAreOff:(AdViewView *)adViewView {
  self.label.text = @"Ads are off";
}

- (void)adViewWillPresentFullScreenModal {
  AWLogInfo(@"SimpleView: will present full screen modal");
}

- (void)adViewDidDismissFullScreenModal {
  AWLogInfo(@"SimpleView: did dismiss full screen modal");
}

- (void)adViewDidReceiveConfig:(AdViewView *)adViewView {
  self.label.text = @"Received config. Requesting ad...";
}

- (BOOL)adViewTestMode {
  return YES;
}

#if 0
- (LangSetType)PreferLangSet {
	return LangSetType_Separated;
}
#endif
#if 0
- (UIColor *)adViewAdBackgroundColor {
  return [UIColor purpleColor];
}

- (UIColor *)adViewTextColor {
  return [UIColor cyanColor];
}
#endif
#pragma mark event methods

- (void)performEvent {
  self.label.text = @"Event performed";
}

- (void)performEvent2:(AdViewView *)adViewView {
  UILabel *replacement = [[UILabel alloc] initWithFrame:KADVIEW_DETAULT_FRAME];
  replacement.backgroundColor = [UIColor blackColor];
  replacement.textColor = [UIColor whiteColor];
  replacement.textAlignment = UITextAlignmentCenter;
  replacement.text = [NSString stringWithFormat:@"Event performed, view %x", adViewView];
  [adViewView replaceBannerViewWith:replacement];
  [replacement release];
  [self adjustAdSize];
  self.label.text = [NSString stringWithFormat:@"Event performed, view %x", adViewView];
}

#pragma mark multitasking methods

- (void)enterForeground:(NSNotification *)notification {
  AWLogInfo(@"SimpleView entering foreground");
  [self.adView updateAdViewConfig];
}

@end
