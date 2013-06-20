//
//  AddMatchOperation.m
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

#import "AddMatchOperation.h"
#import "MatchData.h"
#import "UtilityClasses.h"

@implementation AddMatchOperation

- (id)init
{
    self = [super init];
    
    if(self != nil)
    {        
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        context = [[ThreadMOC alloc] init];
        
        apiRequest = [[APIRequest alloc] init];
        [apiRequest setThreadPriority:1.0];
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
            NSDictionary *newMatchData = [self getMatchDataFromServer];
            if(newMatchData != nil)
            {
                [self addMatch:newMatchData];
            }
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideSearchIndicator" object:nil userInfo:nil];
}

- (NSDictionary*)getMatchDataFromServer
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = 'M' OR status = 'P'"];
    [request setPredicate:predicate];
    [request setIncludesPropertyValues:NO];

    NSError *error = nil;
    int pendingSessions = [context countForFetchRequest:request error:&error];
    [request release];
    
    NSDictionary *apiResult = nil;
    if(pendingSessions < [appDelegate.prefs integerForKey:@"matchLimit"])
    {
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc postNotificationName:@"shouldClearInvalidMatches" object:nil userInfo:nil];

        NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
        NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
        [memberData setValue:memberNoString forKey:@"memberNo"];
        [memberData setValue:[appDelegate.prefs valueForKey:@"active"] forKey:@"active"];
        
        int crossPostedPhotoCount = [appDelegate.prefs integerForKey:@"crossPostedPhotoCount"];
        [memberData setValue:[NSString stringWithFormat:@"%d", crossPostedPhotoCount] forKey:@"crossPostedPhotoCount"];
        
        apiResult = [apiRequest sendServerRequest:@"match" withTask:@"findMatch" withData:memberData];
        [memberData release];
    }

	return apiResult;
}

- (void)addMatch:(NSDictionary *)matchResultData
{
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];

	int matchNo = 0;
	if([matchResultData valueForKey:@"matchList"] != [NSNull null] && [matchResultData valueForKey:@"matchList"] != nil)
	{
        NSArray *matchList = [matchResultData valueForKey:@"matchList"];

        if([matchList count] == 0)
        {
            [self addBlankRow];
            UIApplication *yongopalApp = [UIApplication sharedApplication];
            [appDelegate performSelectorOnMainThread:@selector(setApplicationBadgeNumber:) withObject:[NSNumber numberWithInt:yongopalApp.applicationIconBadgeNumber-1] waitUntilDone:NO];
            [appDelegate.prefs setInteger:0 forKey:@"newMatchAlert"];
            [appDelegate.prefs synchronize];
        }
        else
        {
            [self clearBlankRows];
            bool shouldDownloadLocations = NO;

            for(NSDictionary *matchData in matchList)
            {
                if([matchData valueForKey:@"matchNo"] == [NSNull null])
                {
                    continue;
                }

                matchNo = [[matchData valueForKey:@"matchNo"] intValue];
                
                if(matchNo != 0)
                {
                    // check if matchNo exists
                    NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
                    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
                    [matchRequest setEntity:entity];
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = %d", matchNo];
                    [matchRequest setPredicate:predicate];
                    [matchRequest setIncludesPropertyValues:NO];
                    
                    NSError *error = nil;
                    int checkMatchNo = [context countForFetchRequest:matchRequest error:&error];
                    [matchRequest release];
                    
                    if(checkMatchNo == 0)
                    {
                        // reset crosspost count everytime a new match has been added
                        int crossPostedPhotoCount = [appDelegate.prefs integerForKey:@"crossPostedPhotoCount"];
                        if(crossPostedPhotoCount > 3)
                        {
                            [appDelegate.prefs setInteger:crossPostedPhotoCount-3 forKey:@"crossPostedPhotoCount"];
                        }
                        else
                        {
                            [appDelegate.prefs setInteger:0 forKey:@"crossPostedPhotoCount"];
                        }
                        [appDelegate.prefs synchronize];

                        if([[matchData valueForKey:@"memberNo"] intValue] == 0)
                        {
                            shouldDownloadLocations = YES;

                            // add quick match
                            MatchData *newManagedObject = (MatchData*)[NSEntityDescription insertNewObjectForEntityForName:@"MatchData" inManagedObjectContext:context];
                            [newManagedObject setMatchNo:[NSNumber numberWithInt:matchNo]];
                            [newManagedObject setPartnerNo:[NSNumber numberWithInt:0]];
                            [newManagedObject setFirstName:@""];
                            [newManagedObject setStatus:@"M"];
                            [newManagedObject setIsQuickMatch:[matchData valueForKey:@"isQuickMatch"]];
                            [newManagedObject setOrder:[NSNumber numberWithInt:2]];
                            
                            // set regdate
                            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                            [dateFormat setDateFormat:@"yyyy-MM-dd"];
                            
                            NSString *date = [matchData valueForKey:@"regDatetime"];
                            NSDate *regDatetime = [dateFormat dateFromString:date];
                            [newManagedObject setRegDatetime:regDatetime];
                            [dateFormat release];
                            
                            // save data
                            [appDelegate saveContext:context];
                        }
                        else
                        {
                            // add match
                            MatchData *newManagedObject = (MatchData*)[NSEntityDescription insertNewObjectForEntityForName:@"MatchData" inManagedObjectContext:context];
                            
                            // set matchNo
                            [newManagedObject setMatchNo:[NSNumber numberWithInt:matchNo]];
                            
                            // set partnerNo
                            int partnerNo = [[matchData valueForKey:@"memberNo"] intValue];
                            [newManagedObject setPartnerNo:[NSNumber numberWithInt:partnerNo]];
                            
                            // set status
                            [newManagedObject setStatus:@"M"];
                            [newManagedObject setOpen:[NSNumber numberWithBool:YES]];
                            [newManagedObject setOrder:[NSNumber numberWithInt:2]];
                            [newManagedObject setIsQuickMatch:[matchData valueForKey:@"isQuickMatch"]];
                            
                            // set email
                            [newManagedObject setEmail:[matchData valueForKey:@"email"]];
                            
                            // set firstName
                            [newManagedObject setFirstName:[matchData valueForKey:@"firstName"]];
                            
                            // set lastName
                            [newManagedObject setLastName:[matchData valueForKey:@"lastName"]];
                            
                            // set gender
                            [newManagedObject setGender:[matchData valueForKey:@"gender"]];
                            
                            // set birthday
                            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                            [dateFormat setDateFormat:@"yyyy-MM-dd"];
                            NSDate *birthday = [dateFormat dateFromString:[matchData valueForKey:@"birthday"]];
                            [newManagedObject setBirthday:birthday];
                            
                            // set city
                            [newManagedObject setCityName:[matchData valueForKey:@"city"]];
                            
                            // set provinceCode
                            [newManagedObject setProvinceCode:[matchData valueForKey:@"provinceCode"]];
                            
                            // set countryCode
                            [newManagedObject setCountryCode:[matchData valueForKey:@"countryCode"]];
                            
                            // set country
                            [newManagedObject setCountryName:[matchData valueForKey:@"country"]];
                            
                            // set timezoneOffset
                            int timezoneOffset = [[matchData valueForKey:@"timezoneOffset"] intValue];
                            [newManagedObject setTimezoneOffset:[NSNumber numberWithInt:timezoneOffset]];
                            
                            // set timezone
                            [newManagedObject setTimezone:[matchData valueForKey:@"timezone"]];
                            
                            [newManagedObject setLongitude:[NSNumber numberWithFloat:[[matchData valueForKey:@"longitude"] floatValue]]];
                            [newManagedObject setLatitude:[NSNumber numberWithFloat:[[matchData valueForKey:@"latitude"] floatValue]]];
                            
                            // set intro
                            [newManagedObject setIntro:[matchData valueForKey:@"intro"]];
                            
                            // set profileImageNo
                            int profileImageNo = [[matchData valueForKey:@"profileImageNo"] intValue];
                            [newManagedObject setProfileImageNo:[NSNumber numberWithInt:profileImageNo]];
                            
                            // set recentMessage
                            [newManagedObject setRecentMessage:[matchData valueForKey:@"intro"]];
                            
                            // set regdate
                            NSString *date = [matchData valueForKey:@"regDatetime"];
                            NSDate *regDatetime = [dateFormat dateFromString:date];
                            [newManagedObject setRegDatetime:regDatetime];
                            
                            // set expiredate
                            if([matchData valueForKey:@"expireDate"] != [NSNull null])
                            {
                                NSDate *expireDate = [dateFormat dateFromString:[matchData valueForKey:@"expireDate"]];
                                [newManagedObject setExpireDate:expireDate];
                            }
                            
                            // set active date
                            NSDate *activeDate = [dateFormat dateFromString:[matchData valueForKey:@"activeDate"]];
                            [newManagedObject setActiveDate:activeDate];
                            [dateFormat release];
                            
                            // download profile image
                            if(profileImageNo != 0)
                            {
                                // get new profile image
                                [dnc postNotificationName:@"downloadThumbnail" object:nil userInfo:[NSDictionary dictionaryWithObject:[matchData valueForKey:@"memberNo"] forKey:@"memberNo"]];
                            }
                            
                            // reset match end warning
                            [appDelegate.prefs setBool:NO forKey:@"confirmedEndWarning"];
                            
                            // should search for new match
                            [appDelegate.prefs setValue:[NSNumber numberWithBool:YES] forKey:@"shouldRequestNewMatch"];
                            
                            // set last match date
                            [appDelegate.prefs setObject:[UtilityClasses currentUTCDate] forKey:@"lastMatchDate"];
                            
                            [appDelegate.prefs synchronize];
                            
                            // save data
                            [appDelegate saveContext:context];
                        }
                    }
                }
            }

            if(shouldDownloadLocations == YES) [self downloadAllLocations];
        }
	}
	else
	{
        NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"API Error", @"title", @"Request failed", @"message", nil];
		[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:NO];
		[alertContent release];
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

- (void)downloadAllLocations
{    
    NSDictionary *apiResult = [apiRequest sendServerRequest:@"member" withTask:@"getAllLocations" withData:nil];
    if(apiResult != nil)
    {
        if([apiResult valueForKey:@"locations"] != nil && [apiResult valueForKey:@"locations"] != [NSNull null])
        {
            NSArray *locations = [apiResult valueForKey:@"locations"];
            
            NSString *locationsPlistPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/locations.plist"];
            [locations writeToFile:locationsPlistPath atomically:NO];
        }
    }
}

- (void)addBlankRow
{
	NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
    [matchRequest setEntity:entity];
    [matchRequest setIncludesPropertyValues:NO];
    
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = 0"];
	[matchRequest setPredicate:predicate];
    
	NSError *error = nil;
	int currentBlankRows = [context countForFetchRequest:matchRequest error:&error];
    [matchRequest release];
    
	if(currentBlankRows == 0)
	{
		MatchData *newManagedObject = (MatchData*)[NSEntityDescription insertNewObjectForEntityForName:@"MatchData" inManagedObjectContext:context];
        
		// set matchNo
		[newManagedObject setMatchNo:[NSNumber numberWithInt:0]];
        
        int order = -1;
        if([[appDelegate.prefs valueForKey:@"shouldRequestNewMatch"] boolValue] == YES)
        {
            order = 0;
        }
        
		// set status
		[newManagedObject setStatus:@"E"];
		[newManagedObject setOrder:[NSNumber numberWithInt:order]];
        
        // set expire date
        [newManagedObject setActiveDate:[UtilityClasses currentUTCDate]];
        
        [newManagedObject setFirstName:@""];
        [newManagedObject setPartnerNo:[NSNumber numberWithInt:0]];
        
		// save data
		[appDelegate saveContext:context];
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
