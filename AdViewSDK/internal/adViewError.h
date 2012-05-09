/*

 AdViewError.h

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

#import <Foundation/Foundation.h>

#define AdViewErrorDomain @"com.adview.sdk.ErrorDomain"

enum {
  AdViewConfigConnectionError = 10, /* Cannot connect to config server */
  AdViewConfigStatusError = 11, /* config server did not return 200 */
  AdViewConfigParseError = 20, /* Error parsing config from server */
  AdViewConfigDataError = 30,  /* Invalid config format from server */
  AdViewCustomAdConnectionError = 40, /* Cannot connect to custom ad server */
  AdViewCustomAdParseError = 50, /* Error parsing custom ad from server */
  AdViewCustomAdDataError = 60, /* Invalid custom ad data from server */
  AdViewCustomAdImageError = 70, /* Cannot create image from data */
  AdViewAdRequestIgnoredError = 80, /* ignoreNewAdRequests flag is set */
  AdViewAdRequestInProgressError = 90, /* ad request in progress */
  AdViewAdRequestNoConfigError = 100, /* no configurations for ad request */
  AdViewAdRequestTooSoonError = 110, /* requesting ad too soon */
  AdViewAdRequestNoMoreAdNetworks = 120, /* no more ad networks for rollover */
  AdViewAdRequestNoNetworkError = 130, /* no network connection */
  AdViewAdRequestModalActiveError = 140 /* modal view active */
};

@interface AdViewError : NSError {

}

+ (AdViewError *)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)dict;
+ (AdViewError *)errorWithCode:(NSInteger)code description:(NSString *)desc;
+ (AdViewError *)errorWithCode:(NSInteger)code description:(NSString *)desc underlyingError:(NSError *)uError;

- (id)initWithCode:(NSInteger)code userInfo:(NSDictionary *)dict;
- (id)initWithCode:(NSInteger)code description:(NSString *)desc;
- (id)initWithCode:(NSInteger)code description:(NSString *)desc underlyingError:(NSError *)uError;

@end
