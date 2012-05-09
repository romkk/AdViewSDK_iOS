/*

 TableController.m

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
#import "TableController.h"
#import "AdViewView.h"
#import "SampleConstants.h"


@implementation TableController

@synthesize adView;

- (id)init {
  if (self = [super initWithNibName:@"TableController" bundle:nil]) {
    self.title = @"Ad In Table";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.adView = [AdViewView requestAdViewViewWithDelegate:self];
  self.adView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;

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
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.adView rotateToOrientation:toInterfaceOrientation];
  [self adjustAdSize];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (UILabel *)label {
  return (UILabel *)[self.view viewWithTag:1337];
}

- (UITableView *)table {
  return (UITableView *)[self.view viewWithTag:3337];
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

- (void)dealloc {
  self.adView.delegate = nil;
  self.adView = nil;
  [super dealloc];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 10;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  static NSString *CellIdentifier = @"Cell";
  static NSString *AdCellIdentifier = @"AdCell";

  NSString *cellId = CellIdentifier;
  if (indexPath.row == 0) {
    cellId = AdCellIdentifier;
  }

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    if ([UITableViewCell instancesRespondToSelector:@selector(initWithStyle:reuseIdentifier:)]) {
      // iPhone SDK 3.0
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
    }
    else {
      // iPhone SDK 2.2.1
      cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellId] autorelease];
    }
    if (cellId == AdCellIdentifier) {
      [cell.contentView addSubview:adView];
    }
  }

  switch (indexPath.row) {
    case 0:
      break;
    case 1:
      if ([cell respondsToSelector:@selector(textLabel)]) {
        // iPhone SDK 3.0
        cell.textLabel.text = @"Request New Ad";
      }
      else {
        // iPhone SDK 2.2.1
        //cell.text = @"Request New Ad";
      }
      break;
    case 2:
      if ([cell respondsToSelector:@selector(textLabel)]) {
        // iPhone SDK 3.0
        cell.textLabel.text = @"Roll Over";
      }
      else {
        // iPhone SDK 2.2.1
        //cell.text = @"Roll Over";
      }
      break;
    default:
      if ([cell respondsToSelector:@selector(textLabel)]) {
        // iPhone SDK 3.0
        cell.textLabel.text = [NSString stringWithFormat:@"Cell %d", indexPath.row];
      }
      else {
        // iPhone SDK 2.2.1
        //cell.text = [NSString stringWithFormat:@"Cell %d", indexPath.row];
      }
  }

  return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.row) {
    case 1:
      self.label.text = @"Request New Ad pressed! Requesting...";
      [adView requestFreshAd];
      break;
    case 2:
      self.label.text = @"Roll Over pressed! Requesting...";
      [adView rollOver];
      break;
  }
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0 && indexPath.row == 0) {
    return CGRectGetHeight(adView.bounds);
  }
  return self.table.rowHeight;
}


#pragma mark AdViewDelegate methods

- (NSString *)adViewApplicationKey {
  return kSampleAppKey;
}

- (UIViewController *)viewControllerForPresentingModalView {
  return [((AdViewSDK_SampleAppDelegate *)[[UIApplication sharedApplication] delegate]) navigationController];
}

- (void)adViewStartGetAd:(AdViewView *)adViewView {
	self.label.text = [NSString stringWithFormat:
					   @"Go to ad %@, size %@",
					   [adViewView mostRecentNetworkName],
					   NSStringFromCGSize([adViewView actualAdSize])];
	[self adjustAdSize];	
}

- (void)adViewDidReceiveAd:(AdViewView *)adViewView {
  self.label.text = [NSString stringWithFormat:
                     @"Got ad from %@, size %@",
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
    [self adjustAdSize];
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

- (void)adViewDidAnimateToNewAdIn:(AdViewView *)adViewView {
  [self.table reloadData];
}

- (void)adViewReceivedNotificationAdsAreOff:(AdViewView *)adViewView {
  self.label.text = @"Ads are off";
}

- (void)adViewWillPresentFullScreenModal {
  NSLog(@"TableView: will present full screen modal");
}

- (void)adViewDidDismissFullScreenModal {
  NSLog(@"TableView: did dismiss full screen modal");
}

- (void)adViewDidReceiveConfig:(AdViewView *)adViewView {
  self.label.text = @"Received config. Requesting ad...";
}

- (BOOL)adViewTestMode {
  return YES;
}

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

@end

