//
//  UtilityClasses.m
//  YongoPal
//
//  Created by Jiho Kang on 4/23/11.
//  Copyright 2011 BetaStudios, Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "UtilityClasses.h"
#import "Keys.h"
#import <stdlib.h>
#import <time.h>

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

// Ethernet CSMACD
#if ! defined(IFT_ETHER)
#define IFT_ETHER 0x6
#endif

@implementation UtilityClasses

- (id)init
{
	self = [super init];
	if(self)
	{
		
	}
	return self;
}

+ (CLLocationCoordinate2D)geocode:(NSString*)locationString
{
	YongoPalAppDelegate *appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if([appDelegate.networkStatus boolValue] == NO)
    {
        return CLLocationCoordinate2DMake(0, 0);
    }
    
	[appDelegate didStartNetworking];
    
	SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?address=%@&sensor=false", [locationString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];

	NSError *error = nil;
	NSData *response = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:&error];
	[appDelegate didStopNetworking];

	NSString *json_string = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSDictionary *apiResult = [jsonParser objectWithString:json_string error:nil];

    NSArray *resultArray = [apiResult valueForKey:@"results"];
	NSMutableDictionary *locationData = [NSMutableDictionary dictionary];
	if([resultArray count] != 0)
	{
        NSDictionary *geometry = [[resultArray objectAtIndex:0] valueForKey:@"geometry"];
        locationData = [geometry valueForKey:@"location"];
	}

    [json_string release];
    [jsonParser release];

    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([[locationData valueForKey:@"lat"] floatValue], [[locationData valueForKey:@"lng"] floatValue]);

	return coord;
}

+ (NSDictionary *)reverseGeocode:(float)latitude longitude:(float)longitude sensorOn:(BOOL)sensorOn
{
    NSString *sensorOnString = @"false";
    if(sensorOn == YES)
    {
        sensorOnString = @"true";
    }
    
    
	YongoPalAppDelegate *appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if([appDelegate.networkStatus boolValue] == NO)
    {
        return nil;
    }
    
	[appDelegate didStartNetworking];

	SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&sensor=%@",latitude, longitude, sensorOnString]]];
    
	NSError *error = nil;
	NSData *response = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:&error];

	NSString *json_string = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
	NSDictionary *apiResult = [jsonParser objectWithString:json_string error:nil];
    [json_string release];
    
	NSArray *resultArray = [apiResult valueForKey:@"results"];
	NSMutableDictionary *locationData = [NSMutableDictionary dictionary];
	if([resultArray count] != 0)
	{
        NSArray *components = [[resultArray objectAtIndex:0] valueForKey:@"address_components"];
        NSDictionary *geometry = [resultArray valueForKey:@"geometry"];
        NSDictionary *location = [geometry valueForKey:@"location"];
        [locationData setValue:[location valueForKey:@"lat"] forKey:@"lat"];
        [locationData setValue:[location valueForKey:@"lng"] forKey:@"lng"];

        for(NSDictionary *params in components)
        {
            NSPredicate *localityFilter = [NSPredicate predicateWithFormat:@"SELF contains[c] 'locality'"];
            NSPredicate *level1Filter = [NSPredicate predicateWithFormat:@"SELF contains[c] 'administrative_area_level_1'"];
            NSPredicate *countryFilter = [NSPredicate predicateWithFormat:@"SELF contains[c] 'country'"];
            
            NSArray *types = [params valueForKey:@"types"];
            
            if([[types filteredArrayUsingPredicate:localityFilter] count] > 0)
            {
                [locationData setValue:[params valueForKey:@"long_name"] forKey:@"cityName"];
            }
            
            if([[types filteredArrayUsingPredicate:level1Filter] count] > 0)
            {
                [locationData setValue:[params valueForKey:@"long_name"] forKey:@"provinceName"];
                if([[params valueForKey:@"short_name"] length] < 5)
                {
                    [locationData setValue:[params valueForKey:@"short_name"] forKey:@"provinceCode"];
                }
            }
            
            if([[types filteredArrayUsingPredicate:countryFilter] count] > 0)
            {
                [locationData setValue:[params valueForKey:@"short_name"] forKey:@"countryCode"];
                [locationData setValue:[params valueForKey:@"long_name"] forKey:@"countryName"];
            }
        }
	}
    
    // get timezone
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/timezone/json?location=%f,%f&timestamp=%f&sensor=%@",latitude, longitude, timestamp, sensorOnString]]];
    response = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:&error];
	[appDelegate didStopNetworking];
    
    json_string = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
	apiResult = [jsonParser objectWithString:json_string error:nil];
    NSString *timeZoneId = [apiResult valueForKey:@"timeZoneId"];
    [locationData setValue:timeZoneId forKey:@"timezone"];

    [jsonParser release];
	[json_string release];
    
    if(![locationData valueForKey:@"cityName"])
    {
        locationData = nil;
    }

	return locationData;
}

+ (NSDictionary *)getDataFromFBID:(long long int)fbid
{
	YongoPalAppDelegate *appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if([appDelegate.networkStatus boolValue] == NO)
    {
        return nil;
    }
    
	SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];

	[appDelegate didStartNetworking];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://graph.facebook.com/%lld", fbid]]];

	NSError *error = nil;
	NSData *response = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:&error];
	[appDelegate didStopNetworking];

	NSString *json_string = [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
	
	NSDictionary *apiResult = [jsonParser objectWithString:json_string error:nil];
	NSDictionary *results = nil;

	if([apiResult count] > 0)
	{
		results = apiResult;
	}

	return results;
}

+ (int)age:(NSDate *)dateOfBirth
{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *dateComponentsNow = [calendar components:unitFlags fromDate:[NSDate date]];
	NSDateComponents *dateComponentsBirth = [calendar components:unitFlags fromDate:dateOfBirth];
	
	if (([dateComponentsNow month] < [dateComponentsBirth month]) || (([dateComponentsNow month] == [dateComponentsBirth month]) && ([dateComponentsNow day] < [dateComponentsBirth day])))
	{
		return [dateComponentsNow year] - [dateComponentsBirth year] - 1;
	}
	else
	{
		return [dateComponentsNow year] - [dateComponentsBirth year];
	}
}

+ (NSDate*)currentUTCDate
{
	NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeZone:timeZone];
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];
	NSString *UTCString = [dateFormatter stringFromDate:[NSDate date]];
	[dateFormatter release];
	
	NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
	[dateFormatter2 setDateFormat:@"yyyy-MM-dd"];
	NSDate *todayUTC = [dateFormatter2 dateFromString:UTCString];
	[dateFormatter2 release];
	
	return todayUTC;
}

+ (NSArray *)findFiles:(NSString *)extension
{
    NSMutableArray *matches = [[[NSMutableArray alloc] init] autorelease];
    NSFileManager *manager = [NSFileManager defaultManager];

    NSString *item;
    NSArray *contents = [manager contentsOfDirectoryAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] error:nil];
    for(item in contents)
    {
        if([[item pathExtension] isEqualToString:extension])
        {
            [matches addObject:item];
        }
    }
	
    return matches;
}

+ (NSString*)generateKey
{
    YongoPalAppDelegate *appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];

    NSManagedObjectContext *threadContext = [ThreadMOC context];

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Keys" inManagedObjectContext:threadContext];
    [request setEntity:entity];

    NSSortDescriptor *sortDescripter = [[NSSortDescriptor alloc] initWithKey:@"key" ascending:NO];
	NSArray *sortDescripters = [[NSArray alloc] initWithObjects:sortDescripter, nil];
	[request setSortDescriptors:sortDescripters];
	[sortDescripters release];
	[sortDescripter release];

    [request setFetchLimit:1];

    NSError *error = nil;
    NSArray *fetchedObjects = [threadContext executeFetchRequest:request error:&error];
    [request release];

    if(fetchedObjects == nil)
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    int instanceNo = [appDelegate.prefs integerForKey:@"instanceNo"];
    long long int newKey = 0;

    if([fetchedObjects count] == 0)
    {
        NSTimeInterval microsecondDate = ([[NSDate date] timeIntervalSince1970] * 10000);
        newKey = (long long int)microsecondDate;
    }
    else
    {
        NSTimeInterval microsecondDate = ([[NSDate date] timeIntervalSince1970] * 10000);
        Keys *keyObj = [fetchedObjects objectAtIndex:0];
        long long int currentKey = [[keyObj valueForKey:@"key"] longLongValue];
        
        newKey = (long long int)microsecondDate;
        while(currentKey == newKey)
        {
            newKey = newKey + 1;
        }
    }
    NSString *keyString = [NSString stringWithFormat:@"%d-%lld", instanceNo, newKey];

    Keys *newManagedObject = (Keys*)[NSEntityDescription insertNewObjectForEntityForName:@"Keys" inManagedObjectContext:threadContext];
    [newManagedObject setInstanceNo:[NSNumber numberWithInt:instanceNo]];
    [newManagedObject setKey:[NSNumber numberWithLongLong:newKey]];
    [newManagedObject setKeyString:keyString];
    [appDelegate saveContext:threadContext];

    return keyString;
}

+ (NSString*)saveImageData:(NSData*)imageData named:(NSString*)imageName withKey:(NSString*)key overwrite:(bool)overwrite
{
    NSString *imageFile = [NSString stringWithFormat:@"Documents/Images/%@_%@.jpg", key, imageName];
    NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:imageFile];

    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:imagePath];

    if(overwrite == YES && fileExists == YES)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;

        BOOL success = [fm removeItemAtPath:imagePath error:&error];
        if (!success || error)
        {
            return nil;
        }
    }
    else if(overwrite == NO && fileExists == YES)
    {
        return nil;
    }

    if(imageData != nil)
    {
        if([imageData writeToFile:imagePath atomically:YES])
        {
            return imageFile;
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

+ (NSString*)saveCacheImageData:(NSData*)imageData named:(NSString*)imageName withKey:(NSString*)key overwrite:(bool)overwrite
{
    NSString *imageFile = [NSString stringWithFormat:@"%@_%@.jpg", key, imageName];
    NSString *imagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:imageFile];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
    
    if(overwrite == YES && fileExists == YES)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        
        BOOL success = [fm removeItemAtPath:imagePath error:&error];
        if (!success || error)
        {
            return nil;
        }
    }
    else if(overwrite == NO && fileExists == YES)
    {
        return nil;
    }

    if(imageData != nil)
    {
        if([imageData writeToFile:imagePath atomically:YES])
        {
            return imageFile;
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

+ (NSString*)getWiFiIPAddress
{
    BOOL success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor = NULL;

    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            // this second test keeps from picking up the loopback address
            if(cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                // found the WiFi adapter
                if ([name isEqualToString:@"en0"])
                { 
                    freeifaddrs(addrs);
                    return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                }
            }
            cursor = cursor->ifa_next;
        }
    }
    freeifaddrs(addrs);
    return nil;
}

+ (BOOL)validateEmail:(NSString *)candidate
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    return [emailTest evaluateWithObject:candidate];
}

+ (void)resetEntity:(NSString*)entityName
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    YongoPalAppDelegate *appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    NSFetchRequest *allData = [[NSFetchRequest alloc] init];
	[allData setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:threadContext]];
	[allData setIncludesPropertyValues:NO];
	NSArray *dataArray = [threadContext executeFetchRequest:allData error:&error];
	[allData release];
	for (NSManagedObject *object in dataArray)
	{
		[threadContext deleteObject:object];
	}
    
    [appDelegate saveContext:threadContext];
    [pool drain];
}

+ (float)viewHeightWithStatusBar:(bool)statusBar andNavBar:(bool)navBar
{
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    YongoPalAppDelegate *appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    float height = appDelegate.window.frame.size.height;

    if(statusBar == YES)
    {
        height -= statusBarFrame.size.height;
    }

    if(navBar == YES)
    {
        height -= 44;
    }

    return height;
}

- (void)dealloc
{
    [super dealloc];
}

@end
