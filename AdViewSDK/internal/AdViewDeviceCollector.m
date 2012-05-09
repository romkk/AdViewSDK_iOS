//
//  AdViewDeviceCollector.m
//  AdViewDeviceCollector
//
//  Created by Zhang Kerberos on 11-9-9.
//  Copyright 2011年 Access China. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "AdViewDeviceCollector.h"
#import "AdViewReachability.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "adViewLog.h"

#define ADVIEW_DEVICE_COLLECTOR_REPORT_HOST @"report.adview.cn"
#define ADVIEW_DEVICE_COLLECTOR_REPORT_FORMAT @"http://%@/agent/appReport.php?keyAdView=%@&keyDev=%@&typeDev=%@&osVer=%@&resolution=%@&servicePro=%@&netType=%@&channel=%@&platform=%@"

typedef enum {
    kAdViewDeviceCollectorStatusNotPost = 0,
    kAdViewDeviceCollectorStatusPosting,
    kAdViewDeviceCollectorStatusPosted,
    kAdViewDeviceCollectorStatusMax,
} AdViewDeviceCollectorStatus;

static AdViewDeviceCollector* shared_adview_device_collector = nil;
static AdViewDeviceCollectorStatus shared_adview_device_collector_status = kAdViewDeviceCollectorStatusNotPost;

@implementation AdViewDeviceCollector
@synthesize delegate;

+ (AdViewDeviceCollectorStatus) deviceCollectorStatus
{
    return shared_adview_device_collector_status;
}

+ (AdViewDeviceCollector*) sharedDeviceCollector
{
    @synchronized ([AdViewDeviceCollector class]) {
        if (shared_adview_device_collector == nil) {
            shared_adview_device_collector = [[AdViewDeviceCollector alloc] init];
        }
    }
    return shared_adview_device_collector;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized ([AdViewDeviceCollector class]) {
        if (shared_adview_device_collector == nil) {
            shared_adview_device_collector = [super allocWithZone:zone];
        }
    }
    return shared_adview_device_collector;
}

- (NSUInteger) retainCount {
    return NSUIntegerMax;
}

- (oneway void) release {
    
}

- (id) retain {
    return shared_adview_device_collector;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        //[self deviceInformation];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSString*) urlEncode: (NSString*) string
{
    NSMutableString *escaped = [NSMutableString stringWithString: [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSRange wholeString = NSMakeRange(0, escaped.length);
    [escaped replaceOccurrencesOfString:@"$" withString:@"%24" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:wholeString];
    [escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:wholeString];
    return escaped;
}
- (void)postDeviceInformation
{
    if (shared_adview_device_collector_status == kAdViewDeviceCollectorStatusNotPost) {
        //post
        shared_adview_device_collector_status = kAdViewDeviceCollectorStatusPosting;
        NSString* appKey = @"testkey/%fadsfa";
        NSString* marketChannel = @"";
        if ([self.delegate respondsToSelector:@selector(appKey)]) {
            appKey = [self.delegate performSelector:@selector(appKey)];
        }
        if ([self.delegate respondsToSelector:@selector(marketChannel)]) {
            marketChannel = [self.delegate performSelector:@selector(marketChannel)];
        }
        NSString* report_url = [NSString stringWithFormat:ADVIEW_DEVICE_COLLECTOR_REPORT_FORMAT,
								ADVIEW_DEVICE_COLLECTOR_REPORT_HOST,
                                [self urlEncode:appKey],
                                [self urlEncode: [self deviceId]],
                                [self urlEncode: [self deviceModel]],
                                [self urlEncode: [self systemVersion]],
                                [self urlEncode: [self screenResolution]],
                                [self urlEncode: [self serviceProviderCode]],
                                [self urlEncode: [self networkType]],
                                [self urlEncode: marketChannel],
                                [self urlEncode: [self systemName]]
                                ];
        AWLogInfo(@"%@", report_url);
        NSURL *url = [NSURL URLWithString: report_url];
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        [NSURLConnection connectionWithRequest:req delegate:self];
    }
}

- (NSString*) deviceId
{
    return [[UIDevice currentDevice] uniqueIdentifier];
}

- (NSString*) deviceModel
{
    return [[UIDevice currentDevice] model];
}

- (NSString*) systemVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString*) systemName
{
    return [[UIDevice currentDevice] systemName];
}

- (NSString*) screenResolution
{
    NSString* screenResolution = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // iPad
        screenResolution = @"1024*768";
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        // iPhone
        screenResolution = @"480*320";
    } else {
        // Unknown
        screenResolution = @"Unknown";
    }
    
    return screenResolution;
}

- (NSString*) serviceProviderCode
{
    NSString* serviceProviderCode;
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    //NSString *carrierName = [carrier carrierName];
    NSString *carrierCountryCode = [carrier mobileCountryCode];
    NSString *carrierNetworkCode = [carrier mobileNetworkCode];
    NSString* deviceModel = [[UIDevice currentDevice] model];
    NSRange simulatorRange = [deviceModel rangeOfString:@"Simulator"];
    if (simulatorRange.location != NSNotFound) {
        serviceProviderCode = @"Unknown";
    } else {
        serviceProviderCode = [NSString stringWithFormat:@"%@%@", carrierCountryCode, carrierNetworkCode];
    }
    return serviceProviderCode;
}

- (NSString*) networkType
{
    NSString* netType = nil;
    AdViewNetworkStatus netStatus = [[AdViewReachability reachabilityForInternetConnection] currentReachabilityStatus];
    switch (netStatus) {
        case AdViewNotReachable:
            netType = @"Unknown";
            break;
        case AdViewReachableViaWiFi:
            netType = @"Wi-Fi";
            break;
        case AdViewReachableViaWWAN:
            netType = @"2G/3G";
            break;
        default:
            break;
    }
    return netType;
}

#pragma mark - URLConnection
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    shared_adview_device_collector_status = kAdViewDeviceCollectorStatusNotPost;
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    AWLogInfo(@"Recive Data %@", string);
    [string release];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    shared_adview_device_collector_status = kAdViewDeviceCollectorStatusPosted;
}
@end