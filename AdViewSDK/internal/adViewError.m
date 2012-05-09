/*

 AdViewError.m
 
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

#import "AdViewError.h"

@implementation AdViewError

+ (AdViewError *)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)dict {
  return [[[AdViewError alloc] initWithCode:code userInfo:dict] autorelease];
}

+ (AdViewError *)errorWithCode:(NSInteger)code description:(NSString *)desc {
  return [[[AdViewError alloc] initWithCode:code description:desc] autorelease];
}

+ (AdViewError *)errorWithCode:(NSInteger)code description:(NSString *)desc underlyingError:(NSError *)uError {
  return [[[AdViewError alloc] initWithCode:code description:desc underlyingError:uError] autorelease];
}

- (id)initWithCode:(NSInteger)code userInfo:(NSDictionary *)dict {
  return [super initWithDomain:AdViewErrorDomain code:code userInfo:dict];
}

- (id)initWithCode:(NSInteger)code description:(NSString *)desc {
  NSDictionary *eInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                         desc, NSLocalizedDescriptionKey,
                         nil];
  return [super initWithDomain:AdViewErrorDomain code:code userInfo:eInfo];
}

- (id)initWithCode:(NSInteger)code description:(NSString *)desc underlyingError:(NSError *)uError {
  NSDictionary *eInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                         desc, NSLocalizedDescriptionKey,
                         uError, NSUnderlyingErrorKey,
                         nil];
  return [super initWithDomain:AdViewErrorDomain code:code userInfo:eInfo];
}

@end
