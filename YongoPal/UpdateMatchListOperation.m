//
//  UpdateMatchListOperation.m
//  Wander
//
//  Created by Jiho Kang on 10/6/11.
//  Copyright (c) 2011 YongoPal, Inc. All rights reserved.
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

#import "UpdateMatchListOperation.h"
#import "MatchData.h"
#import "UtilityClasses.h"

@implementation UpdateMatchListOperation

- (id)init
{
    self = [super init];

    if(self != nil)
    {
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        context = [[ThreadMOC alloc] init];
        
        apiRequest = [[APIRequest alloc] init];
        [apiRequest setThreadPriority:0.1];
    }
    
    return self;
}

- (void)dealloc
{
    [context release];
    [apiRequest release];
    [super dealloc];
}

- (void)main
{
    @try
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        if([self isCancelled] == NO)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldClearInvalidMatches" object:nil userInfo:nil];
            NSArray *matchList = [self getMatchListFromServer];
            [self setMatchList:matchList];
        }

        [pool drain];
    }
    @catch (NSException *e)
    {
        if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
        {
            NSLog(@"Exception %@", e);
        }
    }
}

- (NSArray*)getMatchListFromServer
{
    NSArray *pendingSessions = [NSArray arrayWithArray:[self pendingSessions]];
    
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
    [memberData setObject:pendingSessions forKey:@"pendingSessions"];
    if([self hasCurrentQuickMatch] == YES) [memberData setValue:@"Y" forKey:@"hasQuickMatch"];
    else [memberData setValue:@"N" forKey:@"hasQuickMatch"];
	NSDictionary *apiResult = [apiRequest sendServerRequest:@"match" withTask:@"getMatchList" withData:memberData];
	[memberData release];
	
    NSArray *matchList = nil;
    if(apiResult)
    {
        matchList = [apiResult valueForKey:@"matchList"];
        NSString *matchPriority = [apiResult valueForKey:@"matchPriority"];
        NSString *multipleMatchLimit = [apiResult valueForKey:@"multipleMatchLimit"];
        
        if(![matchPriority isEqual:[NSNull null]])
        {
            [appDelegate.prefs setInteger:[matchPriority intValue] forKey:@"matchPriority"];
        }
        
        if(![multipleMatchLimit isEqual:[NSNull null]])
        {
            [appDelegate.prefs setInteger:[multipleMatchLimit intValue] forKey:@"matchLimit"];
        }
        [appDelegate.prefs synchronize];
    }

    return matchList;
}

- (void)setMatchList:(NSArray*)matchList
{
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];

    if([matchList count] > 0)
	{
		NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
        [matchRequest setEntity:entity];
        [matchRequest setIncludesPropertyValues:NO];

        bool shouldDownloadLocations = NO;
		for(NSDictionary *matchData in matchList)
		{
            // check for invalid match numbers
            if([matchData valueForKey:@"matchNo"] == [NSNull null] || [matchData valueForKey:@"matchNo"] == nil)
            {
                continue;
            }
            
            NSAutoreleasePool *pool = [NSAutoreleasePool new];
            
			int currentMatchNo = [[matchData valueForKey:@"matchNo"] intValue];
            if(currentMatchNo == 0)
            {
                continue;
            }
            
			NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo = %d", currentMatchNo]];
			[matchRequest setPredicate:predicate];
			
			NSError *error = nil;
			NSUInteger count = [context countForFetchRequest:matchRequest error:&error];
			
			if(count == 0)
			{
                [self clearBlankRows];

				// save in core data
				MatchData *newManagedObject = (MatchData*)[NSEntityDescription insertNewObjectForEntityForName:@"MatchData" inManagedObjectContext:context];
                
				// set matchNo
				NSNumber *matchNo = [NSNumber numberWithInt:currentMatchNo];
				[newManagedObject setMatchNo:matchNo];
                
                // set partnerNo
                NSNumber *partnerNo = [NSNumber numberWithInt:[[matchData valueForKey:@"memberNo"] intValue]];
                [newManagedObject setPartnerNo:partnerNo];
                
                // set first name
                [newManagedObject setFirstName:[matchData valueForKey:@"firstName"]];
                
                // set quick match
                if([matchData valueForKey:@"isQuickMatch"] != [NSNull null])
                {
                    [newManagedObject setIsQuickMatch:[matchData valueForKey:@"isQuickMatch"]];
                }

                // if not quick match
                int profileImageNo;
                if([[matchData valueForKey:@"memberNo"] intValue] == 0)
                {
                    shouldDownloadLocations = YES;
                }
                else
                {
                    // set email
                    [newManagedObject setEmail:[matchData valueForKey:@"email"]];

                    // set last name
                    [newManagedObject setLastName:[matchData valueForKey:@"lastName"]];
                    
                    // set gender
                    [newManagedObject setGender:[matchData valueForKey:@"gender"]];
                    
                    // set birthday
                    [dateFormat setDateFormat:@"yyyy-MM-dd"];
                    NSDate *birthday = [dateFormat dateFromString:[matchData valueForKey:@"birthday"]];
                    [newManagedObject setBirthday:birthday];
                    
                    // set city name
                    [newManagedObject setCityName:[matchData valueForKey:@"city"]];
                    
                    // set provinceCode
                    [newManagedObject setProvinceCode:[matchData valueForKey:@"provinceCode"]];
                    
                    // set country name
                    [newManagedObject setCountryName:[matchData valueForKey:@"country"]];
                    
                    // set countryCode
                    [newManagedObject setCountryCode:[matchData valueForKey:@"countryCode"]];
                    
                    // set latitude and longitude
                    if([[matchData valueForKey:@"latitude"] floatValue] != 0) [newManagedObject setLatitude:[NSNumber numberWithFloat:[[matchData valueForKey:@"latitude"] floatValue]]];
                    if([[matchData valueForKey:@"longitude"] floatValue] != 0)[newManagedObject setLongitude:[NSNumber numberWithFloat:[[matchData valueForKey:@"longitude"] floatValue]]];
                    
                    // set intro
                    if([matchData valueForKey:@"intro"] != [NSNull null])
                    {
                        [newManagedObject setIntro:[matchData valueForKey:@"intro"]];
                    }
                    
                    // set profileImageNo
                    profileImageNo = [[matchData valueForKey:@"profileImageNo"] intValue];
                    [newManagedObject setProfileImageNo:[NSNumber numberWithInt:profileImageNo]];
                    
                    // set recentMessage
                    if([matchData valueForKey:@"recentMessage"] != [NSNull null])
                    {
                        if(![[matchData valueForKey:@"recentMessage"] isEqualToString:@""])
                        {
                            [newManagedObject setRecentMessage:[matchData valueForKey:@"recentMessage"]];
                        }
                        else if([matchData valueForKey:@"intro"] != [NSNull null])
                        {
                            [newManagedObject setRecentMessage:[matchData valueForKey:@"intro"]];
                        }
                    }
                    else if([matchData valueForKey:@"intro"] != [NSNull null])
                    {
                        [newManagedObject setRecentMessage:[matchData valueForKey:@"intro"]];
                    }
                    
                    // set timezoneOffset
                    int timezoneOffset = [[matchData valueForKey:@"timezoneOffset"] intValue];
                    [newManagedObject setTimezoneOffset:[NSNumber numberWithInt:timezoneOffset]];
                    
                    // set timezone
                    [newManagedObject setTimezone:[matchData valueForKey:@"timezone"]];
                    
                    // set expiredate
                    [dateFormat setDateFormat:@"yyyy-MM-dd"];
                    if([matchData valueForKey:@"expireDate"] != [NSNull null])
                    {
                        NSDate *expireDate = [dateFormat dateFromString:[matchData valueForKey:@"expireDate"]];
                        [newManagedObject setExpireDate:expireDate];
                    }
                }
                
                // set active date
                [dateFormat setDateFormat:@"yyyy-MM-dd"];
                if([matchData valueForKey:@"activeDate"] != [NSNull null])
                {
                    NSDate *activeDate = [dateFormat dateFromString:[matchData valueForKey:@"activeDate"]];
                    [newManagedObject setActiveDate:activeDate];
                }
                
                // set reg date
                [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

                NSString *regDateString = [matchData valueForKey:@"regDatetime"];
                NSDate *regDatetime = [dateFormat dateFromString:regDateString];
                [newManagedObject setRegDatetime:regDatetime];
                
                // set match date
                NSString *matchDateString = [matchData valueForKey:@"matchDatetime"];
                NSDate *matchDatetime = [dateFormat dateFromString:matchDateString];
                [newManagedObject setMatchDatetime:matchDatetime];

				// set status
				NSString *status = nil;
                NSString *deleted = nil;
                if([matchData valueForKey:@"matchStatus"] != [NSNull null]) status = [matchData valueForKey:@"matchStatus"];
                if([matchData valueForKey:@"deleted"] != [NSNull null] && [matchData valueForKey:@"deleted"] != nil)
                {
                    deleted = [matchData valueForKey:@"deleted"];
                }

                if([deleted isEqualToString:@"Y"]) [newManagedObject setStatus:@"D"];
                else if(status != nil) [newManagedObject setStatus:status];
                
                // set open
                if([matchData valueForKey:@"open"] != nil && [matchData valueForKey:@"open"] != [NSNull null])
                {
                    NSString *open = [matchData valueForKey:@"open"];
                    bool openBool = YES;
                    if([open isEqualToString:@"N"]) openBool = NO;
                    [newManagedObject setOpen:[NSNumber numberWithBool:openBool]];
                }
                
                // set muted
                if([matchData valueForKey:@"muted"] != nil && [matchData valueForKey:@"muted"] != [NSNull null])
                {
                    NSString *muted = [matchData valueForKey:@"muted"];
                    bool mutedBool = NO;
                    if([muted isEqualToString:@"Y"]) mutedBool = YES;
                    [newManagedObject setMuted:[NSNumber numberWithBool:mutedBool]];
                }

                // set order
				NSNumber *order = 0;
                if([matchData valueForKey:@"order"])
                {
                    // swaped order of current match & new match starting build 200
                    if([[matchData valueForKey:@"order"] intValue] == 1) order = [NSNumber numberWithInt:2];
                    else if([[matchData valueForKey:@"order"] intValue] == 2) order = [NSNumber numberWithInt:1];
                    else order = [NSNumber numberWithInt:[[matchData valueForKey:@"order"] intValue]];
                }

				if(order != 0)
                {
                    [newManagedObject setOrder:order];
                }
                
                if([status isEqualToString:@"P"] || [status isEqualToString:@"Y"])
                {
                    UIApplication *yongopalApp = [UIApplication sharedApplication];
                    [appDelegate setApplicationBadgeNumber:[NSNumber numberWithInt:yongopalApp.applicationIconBadgeNumber-1]];
                    [appDelegate.prefs setInteger:0 forKey:@"newMatchAlert"];
                    [appDelegate.prefs synchronize];
                }
                
                // reset match end warning
                if([status isEqualToString:@"Y"])
                {
                    [appDelegate.prefs setBool:NO forKey:@"confirmedEndWarning"];
                    [appDelegate.prefs synchronize];
                }
                
                if(profileImageNo != 0)
                {                    
                    // get new profile image
                    [dnc postNotificationName:@"downloadThumbnail" object:nil userInfo:[NSDictionary dictionaryWithObject:[matchData valueForKey:@"memberNo"] forKey:@"memberNo"]];
                }
                
                // save data
                [appDelegate saveContext:context];
			}
			else
			{
                [matchRequest setIncludesPropertyValues:YES];
                [matchRequest setReturnsObjectsAsFaults:NO];
                
                NSArray *fetchedObjects = [context executeFetchRequest:matchRequest error:&error];
                
                if(fetchedObjects == nil)
                {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
                
                if([fetchedObjects count] == 0)
                {
                    continue;
                }

				MatchData *selectedMatch = [fetchedObjects objectAtIndex:0];
                
                // set partnerNo
                NSNumber *partnerNo = nil;
                if([matchData valueForKey:@"memberNo"] != [NSNull null]) partnerNo = [NSNumber numberWithInt:[[matchData valueForKey:@"memberNo"] intValue]];
                if(partnerNo != selectedMatch.partnerNo)
                {
                    [selectedMatch setPartnerNo:partnerNo];
                }

                // set email
                NSString *email = nil;
                if([matchData valueForKey:@"email"] != [NSNull null]) email = [matchData valueForKey:@"email"];
                if(![selectedMatch.email isEqualToString:email] && email != nil)
                {
                    [selectedMatch setEmail:[matchData valueForKey:@"email"]];
                }
                
                // set first name
                NSString *firstName = nil;
                if([matchData valueForKey:@"firstName"] != [NSNull null]) firstName = [matchData valueForKey:@"firstName"];
                if(![selectedMatch.firstName isEqualToString:firstName] && firstName != nil)
                {
                    [selectedMatch setFirstName:[matchData valueForKey:@"firstName"]];
                }
                
                // set last name
                NSString *lastName = nil;
                if([matchData valueForKey:@"lastName"] != [NSNull null]) lastName = [matchData valueForKey:@"lastName"];
                if(![selectedMatch.lastName isEqualToString:lastName] && lastName != nil)
                {
                    [selectedMatch setLastName:[matchData valueForKey:@"lastName"]];
                }
                
                // set gender
                NSString *gender = nil;
                if([matchData valueForKey:@"gender"] != [NSNull null]) gender = [matchData valueForKey:@"gender"];
                if(![selectedMatch.gender isEqualToString:gender] && gender != nil)
                {
                    [selectedMatch setGender:[matchData valueForKey:@"gender"]];
                }
                
                // set birthday
                [dateFormat setDateFormat:@"yyyy-MM-dd"];
                NSDate *birthday = nil;
                if([matchData valueForKey:@"birthday"] != [NSNull null]) birthday = [dateFormat dateFromString:[matchData valueForKey:@"birthday"]];
                if(![selectedMatch.birthday isEqualToDate:birthday] && birthday != nil)
                {
                    [selectedMatch setBirthday:birthday];
                }

				NSString *status = nil;
                NSString *deleted = nil;
                if([matchData valueForKey:@"deleted"] != [NSNull null] && [matchData valueForKey:@"deleted"] != nil)
                {
                    deleted = [matchData valueForKey:@"deleted"];
                }                
                
                if([matchData valueForKey:@"matchStatus"] != [NSNull null]) status = [matchData valueForKey:@"matchStatus"];

                if([deleted isEqualToString:@"Y"])
                {
                    [selectedMatch setStatus:@"D"];
                }
				else if(![status isEqualToString:selectedMatch.status])
				{
					// if partner disconnected
					if([status isEqualToString:@"N"])
					{
                        [dnc postNotificationName:@"showDumpedAlert" object:nil userInfo:[NSDictionary dictionaryWithObject:selectedMatch.firstName forKey:@"firstName"]];
					}
					
					// if partner confirmed
					if([selectedMatch.status isEqualToString:@"P"] && [status isEqualToString:@"Y"])
					{
                        UIApplication *yongopalApp = [UIApplication sharedApplication];
                        [appDelegate setApplicationBadgeNumber:[NSNumber numberWithInt:yongopalApp.applicationIconBadgeNumber-1]];
                        [appDelegate.prefs setInteger:0 forKey:@"matchSuccessfulAlert"];
                        [appDelegate.prefs synchronize];
					}
                    
					// update match status
					if(status != nil) [selectedMatch setStatus:status];
				}
                
                // reset match end warning and update expire date
                if([matchData valueForKey:@"expireDate"] != [NSNull null] && [matchData valueForKey:@"expireDate"] != nil)
                {
                    NSTimeInterval selectedExpireDateInterval = [selectedMatch.expireDate timeIntervalSince1970];
                    
                    [dateFormat setDateFormat:@"yyyy-MM-dd"];
                    NSDate *expireDate = [dateFormat dateFromString:[matchData valueForKey:@"expireDate"]];
                    NSTimeInterval expireDateInterval = [expireDate timeIntervalSince1970];
                    
                    if([status isEqualToString:@"Y"] && selectedExpireDateInterval != expireDateInterval)
                    {
                        [selectedMatch setExpireDate:expireDate];
                        [appDelegate.prefs setBool:NO forKey:@"confirmedEndWarning"];
                        [appDelegate.prefs synchronize];
                    }
                }
                
                // set open
                if([matchData valueForKey:@"open"] != nil && [matchData valueForKey:@"open"] != [NSNull null])
                {
                    NSString *open = [matchData valueForKey:@"open"];
                    bool openBool = YES;
                    if([open isEqualToString:@"N"]) openBool = NO;
                    
                    if(openBool != [selectedMatch.open boolValue])
                    {
                        [selectedMatch setOpen:[NSNumber numberWithBool:openBool]];
                    }
                }
                
                // set muted
                if([matchData valueForKey:@"muted"] != nil && [matchData valueForKey:@"muted"] != [NSNull null])
                {
                    NSString *muted = [matchData valueForKey:@"muted"];
                    bool mutedBool = NO;
                    if([muted isEqualToString:@"Y"]) mutedBool = YES;
                    
                    if(mutedBool != [selectedMatch.muted boolValue])
                    {
                        [selectedMatch setMuted:[NSNumber numberWithBool:mutedBool]];
                    }
                }
                
                NSNumber *order = 0;
                if([matchData valueForKey:@"order"] != [NSNull null])
                {
                    // swaped order of current match & new match starting build 200
                    if([[matchData valueForKey:@"order"] intValue] == 1) order = [NSNumber numberWithInt:2];
                    else if([[matchData valueForKey:@"order"] intValue] == 2) order = [NSNumber numberWithInt:1];
                    else order = [NSNumber numberWithInt:[[matchData valueForKey:@"order"] intValue]];
                }

				if(selectedMatch.order != order && order != 0)
				{
					// update match order
					[selectedMatch setOrder:order];
				}
                
				NSString *cityName = nil;
                if([matchData valueForKey:@"city"] != [NSNull null]) cityName = [matchData valueForKey:@"city"];
				if(![cityName isEqualToString:selectedMatch.cityName] && cityName != nil)
				{
					[selectedMatch setCityName:cityName];
				}
                
                // set provinceCode
                NSString *provinceCode = nil;
                if([matchData valueForKey:@"provinceCode"] != [NSNull null]) provinceCode = [matchData valueForKey:@"provinceCode"];
				if(![provinceCode isEqualToString:selectedMatch.provinceCode] && provinceCode != nil)
				{
					[selectedMatch setProvinceCode:provinceCode];
				}
                
				NSString *countryName = nil;
                if([matchData valueForKey:@"country"] != [NSNull null]) countryName = [matchData valueForKey:@"country"];
				if(![countryName isEqualToString:selectedMatch.countryName] && countryName != nil)
				{
					[selectedMatch setCountryName:countryName];
				}
				
				NSString *countryCode = nil;
                if([matchData valueForKey:@"countryCode"] != [NSNull null]) countryCode = [matchData valueForKey:@"countryCode"];
				if(![countryCode isEqualToString:selectedMatch.countryCode] && countryCode != nil)
				{
					[selectedMatch setCountryCode:countryCode];
				}
                
                NSNumber *timezoneOffset = nil;
                if([matchData valueForKey:@"timezoneOffset"] != [NSNull null]) timezoneOffset = [NSNumber numberWithInt:[[matchData valueForKey:@"timezoneOffset"] intValue]];
				if(timezoneOffset != selectedMatch.timezoneOffset && timezoneOffset != nil)
				{
					[selectedMatch setTimezoneOffset:timezoneOffset];
				}
                
                NSString *timezone = nil;
                if([matchData valueForKey:@"timezone"] != [NSNull null]) timezone = [matchData valueForKey:@"timezone"];
				if(![timezone isEqualToString:selectedMatch.timezone] && timezone != nil)
				{
					[selectedMatch setTimezone:timezone];
				}

                if([[matchData valueForKey:@"longitude"] floatValue] != 0 && [[matchData valueForKey:@"latitude"] floatValue] != 0)
                {
                    // if longitude and latitude are 0 gecode city and country
                    NSNumber *longitude = [NSNumber numberWithFloat:[[matchData valueForKey:@"longitude"] floatValue]];
                    if(longitude != selectedMatch.longitude && longitude != nil)
                    {
                        [selectedMatch setLongitude:longitude];
                    }
                    
                    NSNumber *latitude = [NSNumber numberWithFloat:[[matchData valueForKey:@"latitude"] floatValue]];
                    if(latitude != selectedMatch.latitude && latitude != nil)
                    {
                        [selectedMatch setLatitude:latitude];
                    }
                }                
                
                NSString *intro = nil;
                if([matchData valueForKey:@"intro"] != [NSNull null]) intro = [matchData valueForKey:@"intro"];
                if(![intro isEqualToString:selectedMatch.intro] && intro != nil)
                {
                    [selectedMatch setIntro:intro];
                }
                
                // set profileImageNo
                int profileImageNo = 0;
                if([matchData valueForKey:@"profileImageNo"] != [NSNull null]) profileImageNo = [[matchData valueForKey:@"profileImageNo"] intValue];
                if((profileImageNo != 0 && profileImageNo != [selectedMatch.profileImageNo intValue]) || selectedMatch.profileImage == nil)
                {
                    [selectedMatch setProfileImageNo:[NSNumber numberWithInt:profileImageNo]];                    
                    [selectedMatch setProfileImage:nil];
                    
                    // get new profile image
                    [dnc postNotificationName:@"downloadThumbnail" object:nil userInfo:[NSDictionary dictionaryWithObject:[matchData valueForKey:@"memberNo"] forKey:@"memberNo"]];
                }
                
                // set regdate
                if([matchData valueForKey:@"matchDatetime"] != [NSNull null] && [matchData valueForKey:@"matchDatetime"] != nil)
                {
                    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSDate *matchDatetime = [dateFormat dateFromString:[matchData valueForKey:@"matchDatetime"]];

                    if(![selectedMatch.matchDatetime isEqualToDate:matchDatetime])
                    {                    
                        [selectedMatch setMatchDatetime:matchDatetime];
                    }
                }

                // set recentMessage
                if([matchData valueForKey:@"recentMessage"] != [NSNull null])
                {
                    NSString *recentMessage = [matchData valueForKey:@"recentMessage"];
                    if([selectedMatch.recentMessage isEqualToString:@""] && [recentMessage isEqualToString:@""])
                    {
                        [selectedMatch setRecentMessage:[matchData valueForKey:@"intro"]];
                    }
                    else if(![recentMessage isEqualToString:selectedMatch.recentMessage])
                    {
                        [selectedMatch setRecentMessage:recentMessage];
                    }
                }
                else if([matchData valueForKey:@"intro"] != [NSNull null])
                {
                    [selectedMatch setRecentMessage:[matchData valueForKey:@"intro"]];
                }
                
                // save data
                [appDelegate saveContext:context];
			}
            [pool drain];
		}
        [matchRequest release];
        [dateFormat release];

        if(shouldDownloadLocations == YES) [self downloadAllLocations];
	}
}

- (NSArray*)pendingSessions
{
	NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
    [matchRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = 'M' OR status = 'P'"];
	[matchRequest setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [context executeFetchRequest:matchRequest error:&error];
	[matchRequest release];
	
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
    NSMutableArray *sessionArray = [[NSMutableArray alloc] init];
    for(MatchData *pendinSession in fetchedObjects)
    {
        [sessionArray addObject:[pendinSession valueForKey:@"matchNo"]];
    }
    
    return [sessionArray autorelease];
}

- (bool)hasCurrentQuickMatch
{
    NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
    [matchRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = -2"];
	[matchRequest setPredicate:predicate];
    [matchRequest setIncludesPropertyValues:NO];
    
	NSError *error = nil;
	int quickMatchCount = [context countForFetchRequest:matchRequest error:&error];
	[matchRequest release];

    if(quickMatchCount > 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)downloadAllLocations
{
    NSString *locationsPlistPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/locations.plist"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:locationsPlistPath] || [[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
    {
        NSDictionary *apiResult = [apiRequest sendServerRequest:@"member" withTask:@"getAllLocations" withData:nil];
        if(apiResult != nil)
        {
            if([apiResult valueForKey:@"locations"] != nil && [apiResult valueForKey:@"locations"] != [NSNull null])
            {
                NSArray *locations = [apiResult valueForKey:@"locations"];
                [locations writeToFile:locationsPlistPath atomically:NO];
            }
        }
    }
}

- (void)clearBlankRows
{
	NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
    [matchRequest setEntity:entity];
    
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = 0"];
	[matchRequest setPredicate:predicate];
    [matchRequest setIncludesPropertyValues:NO];
    
	NSError *error = nil;
	NSArray *fetchedObjects = [context executeFetchRequest:matchRequest error:&error];
	[matchRequest release];
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
	for(MatchData *matchData in fetchedObjects)
	{
		[context deleteObject:matchData];
	}
	[appDelegate saveContext:context];
}

@end
